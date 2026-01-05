import 'dart:math' as math;

import '../math/math.dart';
import '../primitives/face.dart';
import '../primitives/shape.dart';
import 'shading_style.dart';

/// A 2D point with depth information for rendering.
class _ProjectedPoint {
  final int x;
  final int y;
  final double depth;

  const _ProjectedPoint(this.x, this.y, this.depth);
}

/// Renders solid shapes with Braille-based shading.
///
/// Uses dot density within each Braille cell for brightness levels.
/// 0 dots = dark, 8 dots = bright.
class BrailleSolidRenderer {
  /// Terminal width in characters.
  final int width;

  /// Terminal height in characters.
  final int height;

  /// Sub-pixel width (width * 2).
  int get pixelWidth => width * 2;

  /// Sub-pixel height (height * 4).
  int get pixelHeight => height * 4;

  /// Aspect ratio correction factor for terminal characters.
  final double aspectCorrection;

  /// Light direction (normalized).
  final Vector3 lightDirection;

  /// Ambient light intensity (0-1).
  final double ambientLight;

  /// Brightness buffer at sub-pixel resolution.
  /// Stores brightness values (0-1) for each sub-pixel.
  late final List<List<double>> _brightnessBuffer;

  /// Depth buffer at sub-pixel resolution.
  late final List<List<double>> _depthBuffer;

  /// Creates a Braille solid renderer with the given terminal dimensions.
  BrailleSolidRenderer({
    required this.width,
    required this.height,
    this.aspectCorrection = 2.0,
    Vector3? lightDirection,
    this.ambientLight = 0.1,
  }) : lightDirection =
            (lightDirection ?? Vector3(0.5, 0.8, 1.0)).normalized {
    _brightnessBuffer = List.generate(
      pixelHeight,
      (_) => List.filled(pixelWidth, -1.0), // -1 means empty
    );
    _depthBuffer = List.generate(
      pixelHeight,
      (_) => List.filled(pixelWidth, double.infinity),
    );
  }

  /// Projects a 3D point to sub-pixel screen coordinates.
  /// Returns null if the point is behind the camera (w <= 0).
  _ProjectedPoint? _project(Vector3 point, Matrix4 viewProjection) {
    final m = viewProjection.values;

    final x = m[0] * point.x + m[4] * point.y + m[8] * point.z + m[12];
    final y = m[1] * point.x + m[5] * point.y + m[9] * point.z + m[13];
    final z = m[2] * point.x + m[6] * point.y + m[10] * point.z + m[14];
    final w = m[3] * point.x + m[7] * point.y + m[11] * point.z + m[15];

    if (w <= 0) return null;

    final ndcX = x / w;
    final ndcY = y / w;

    final screenX =
        ((ndcX * aspectCorrection + 1) * 0.5 * pixelWidth).round();
    final screenY = ((1 - ndcY) * 0.5 * pixelHeight).round();

    return _ProjectedPoint(screenX, screenY, z / w);
  }

  /// Renders a shape with solid shading.
  void renderShape(
    Shape shape,
    Matrix4 modelMatrix,
    Matrix4 viewProjection,
    ShadingStyle style,
  ) {
    if (style == ShadingStyle.wireframe) {
      _renderWireframe(shape, modelMatrix, viewProjection);
      return;
    }

    final mvp = viewProjection * modelMatrix;

    // Project all vertices
    final projected = <_ProjectedPoint?>[];
    for (final v in shape.vertices) {
      projected.add(_project(v, mvp));
    }

    // Collect and sort faces by depth (painter's algorithm - back to front)
    final facesWithDepth = <_FaceData>[];

    for (final face in shape.faces) {
      final p0 = projected[face.v0];
      final p1 = projected[face.v1];
      final p2 = projected[face.v2];

      if (p0 == null || p1 == null || p2 == null) continue;

      // Get world-space vertices for normal calculation
      final v0 = shape.vertices[face.v0];
      final v1 = shape.vertices[face.v1];
      final v2 = shape.vertices[face.v2];

      // Calculate face normal in model space
      final edge1 = v1 - v0;
      final edge2 = v2 - v0;
      final localNormal = edge1.cross(edge2).normalized;

      // Transform normal to world space (for lighting)
      final worldNormal = modelMatrix.transformDirection(localNormal).normalized;

      // Back-face culling using screen-space winding order
      final signedArea = (p1.x - p0.x) * (p2.y - p0.y) -
          (p2.x - p0.x) * (p1.y - p0.y);

      if (signedArea >= 0) continue;

      // Calculate brightness based on shading style
      double brightness;
      switch (style) {
        case ShadingStyle.solid:
          brightness = 0.7;
        case ShadingStyle.depth:
          final avgDepth = (p0.depth + p1.depth + p2.depth) / 3;
          brightness = (1 - avgDepth.clamp(-1.0, 1.0)) / 2;
        case ShadingStyle.lit:
          final dotProduct = worldNormal.dot(lightDirection);
          brightness = ambientLight + (1 - ambientLight) * math.max(0.0, dotProduct);
        case ShadingStyle.wireframe:
          brightness = 1.0;
      }

      final avgDepth = (p0.depth + p1.depth + p2.depth) / 3;

      facesWithDepth.add(_FaceData(
        face: face,
        p0: p0,
        p1: p1,
        p2: p2,
        depth: avgDepth,
        brightness: brightness,
      ));
    }

    // Sort back to front
    facesWithDepth.sort((a, b) => b.depth.compareTo(a.depth));

    // Draw faces
    for (final faceData in facesWithDepth) {
      _fillTriangle(
        faceData.p0,
        faceData.p1,
        faceData.p2,
        faceData.brightness,
      );
    }
  }

  /// Renders wireframe only.
  void _renderWireframe(
    Shape shape,
    Matrix4 modelMatrix,
    Matrix4 viewProjection,
  ) {
    final mvp = viewProjection * modelMatrix;

    final projectedVertices = <_ProjectedPoint?>[];
    for (final vertex in shape.vertices) {
      projectedVertices.add(_project(vertex, mvp));
    }

    for (final edge in shape.edges) {
      final p0 = projectedVertices[edge.$1];
      final p1 = projectedVertices[edge.$2];

      if (p0 == null || p1 == null) continue;

      _drawLine(p0.x, p0.y, p1.x, p1.y, 1.0, p0.depth, p1.depth);
    }
  }

  /// Draws a line with given brightness.
  void _drawLine(
    int x0,
    int y0,
    int x1,
    int y1,
    double brightness,
    double depth0,
    double depth1,
  ) {
    int dx = (x1 - x0).abs();
    int dy = -(y1 - y0).abs();
    int sx = x0 < x1 ? 1 : -1;
    int sy = y0 < y1 ? 1 : -1;
    int err = dx + dy;

    int x = x0;
    int y = y0;

    double totalDistSq =
        ((x1 - x0) * (x1 - x0) + (y1 - y0) * (y1 - y0)).toDouble();
    if (totalDistSq == 0) totalDistSq = 1;

    while (true) {
      double currentDistSq =
          ((x - x0) * (x - x0) + (y - y0) * (y - y0)).toDouble();
      double t = (currentDistSq / totalDistSq).clamp(0.0, 1.0);
      double depth = depth0 + (depth1 - depth0) * t;

      _setPixelWithDepth(x, y, brightness, depth);

      if (x == x1 && y == y1) break;

      int e2 = 2 * err;

      if (e2 >= dy) {
        if (x == x1) break;
        err += dy;
        x += sx;
      }

      if (e2 <= dx) {
        if (y == y1) break;
        err += dx;
        y += sy;
      }
    }
  }

  /// Fills a triangle with the given brightness using scanline algorithm.
  void _fillTriangle(
    _ProjectedPoint p0,
    _ProjectedPoint p1,
    _ProjectedPoint p2,
    double brightness,
  ) {
    // Sort vertices by Y coordinate
    var v0 = p0;
    var v1 = p1;
    var v2 = p2;

    if (v0.y > v1.y) {
      final temp = v0;
      v0 = v1;
      v1 = temp;
    }
    if (v0.y > v2.y) {
      final temp = v0;
      v0 = v2;
      v2 = temp;
    }
    if (v1.y > v2.y) {
      final temp = v1;
      v1 = v2;
      v2 = temp;
    }

    // Barycentric depth interpolation
    double depthAt(int x, int y) {
      final denom = (v1.y - v2.y) * (v0.x - v2.x) + (v2.x - v1.x) * (v0.y - v2.y);
      if (denom.abs() < 0.0001) return (v0.depth + v1.depth + v2.depth) / 3;

      final w0 = ((v1.y - v2.y) * (x - v2.x) + (v2.x - v1.x) * (y - v2.y)) / denom;
      final w1 = ((v2.y - v0.y) * (x - v2.x) + (v0.x - v2.x) * (y - v2.y)) / denom;
      final w2 = 1 - w0 - w1;

      return w0 * v0.depth + w1 * v1.depth + w2 * v2.depth;
    }

    _fillFlatBottomTriangle(v0, v1, v2, brightness, depthAt);
    _fillFlatTopTriangle(v0, v1, v2, brightness, depthAt);
  }

  void _fillFlatBottomTriangle(
    _ProjectedPoint v0,
    _ProjectedPoint v1,
    _ProjectedPoint v2,
    double brightness,
    double Function(int, int) depthAt,
  ) {
    if (v1.y == v0.y) return;

    final invSlope1 = (v1.x - v0.x) / (v1.y - v0.y);
    final invSlope2 = (v2.x - v0.x) / (v2.y - v0.y);

    double curX1 = v0.x.toDouble();
    double curX2 = v0.x.toDouble();

    for (int scanY = v0.y; scanY <= v1.y; scanY++) {
      final xStart = curX1.round();
      final xEnd = curX2.round();
      final minX = math.min(xStart, xEnd);
      final maxX = math.max(xStart, xEnd);

      for (int x = minX; x <= maxX; x++) {
        _setPixelWithDepth(x, scanY, brightness, depthAt(x, scanY));
      }

      curX1 += invSlope1;
      curX2 += invSlope2;
    }
  }

  void _fillFlatTopTriangle(
    _ProjectedPoint v0,
    _ProjectedPoint v1,
    _ProjectedPoint v2,
    double brightness,
    double Function(int, int) depthAt,
  ) {
    if (v2.y == v1.y) return;

    final invSlope1 = (v2.x - v1.x) / (v2.y - v1.y);
    final invSlope2 = (v2.x - v0.x) / (v2.y - v0.y);

    double curX1 = v2.x.toDouble();
    double curX2 = v2.x.toDouble();

    for (int scanY = v2.y; scanY > v1.y; scanY--) {
      final xStart = curX1.round();
      final xEnd = curX2.round();
      final minX = math.min(xStart, xEnd);
      final maxX = math.max(xStart, xEnd);

      for (int x = minX; x <= maxX; x++) {
        _setPixelWithDepth(x, scanY, brightness, depthAt(x, scanY));
      }

      curX1 -= invSlope1;
      curX2 -= invSlope2;
    }
  }

  /// Sets a sub-pixel with depth testing.
  void _setPixelWithDepth(int px, int py, double brightness, double depth) {
    if (px < 0 || px >= pixelWidth || py < 0 || py >= pixelHeight) return;

    if (depth < _depthBuffer[py][px]) {
      _brightnessBuffer[py][px] = brightness;
      _depthBuffer[py][px] = depth;
    }
  }

  /// Clears the render buffer.
  void clear() {
    for (final row in _brightnessBuffer) {
      row.fillRange(0, row.length, -1.0);
    }
    for (final row in _depthBuffer) {
      row.fillRange(0, row.length, double.infinity);
    }
  }

  /// Returns the rendered frame as a string.
  ///
  /// Converts brightness values to Braille dot patterns.
  /// Each Braille cell is 2x4 sub-pixels, and we fill dots based on brightness.
  String getFrame() {
    final buffer = StringBuffer();

    for (int cy = 0; cy < height; cy++) {
      for (int cx = 0; cx < width; cx++) {
        // Get all 8 sub-pixels for this cell
        final subPixels = <double>[];
        for (int dy = 0; dy < 4; dy++) {
          for (int dx = 0; dx < 2; dx++) {
            final px = cx * 2 + dx;
            final py = cy * 4 + dy;
            subPixels.add(_brightnessBuffer[py][px]);
          }
        }

        // Calculate cell character
        final char = _brightnessToChar(subPixels);
        buffer.writeCharCode(char);
      }
      if (cy < height - 1) buffer.writeln();
    }

    return buffer.toString();
  }

  /// Converts 8 brightness values (2x4 grid) to a Braille character code.
  ///
  /// We have several strategies:
  /// 1. If all sub-pixels are empty (-1), return empty Braille (U+2800)
  /// 2. For uniform brightness areas, use dot density to represent brightness
  /// 3. For edges/details, preserve the pattern
  int _brightnessToChar(List<double> subPixels) {
    // Check if any sub-pixel is filled
    bool anyFilled = false;
    double avgBrightness = 0;
    int filledCount = 0;

    for (final b in subPixels) {
      if (b >= 0) {
        anyFilled = true;
        avgBrightness += b;
        filledCount++;
      }
    }

    if (!anyFilled) {
      return 0x2800; // Empty Braille character
    }

    avgBrightness /= filledCount;

    // Use dot density based on brightness
    // More dots = brighter, fewer dots = darker
    int dotBits = 0;

    // Braille dot bit mapping (0-indexed in subPixels):
    // Index in subPixels: [0, 1, 2, 3, 4, 5, 6, 7]
    // Which maps to:
    // dx=0,dy=0 -> idx 0 -> bit 0
    // dx=1,dy=0 -> idx 1 -> bit 3
    // dx=0,dy=1 -> idx 2 -> bit 1
    // dx=1,dy=1 -> idx 3 -> bit 4
    // dx=0,dy=2 -> idx 4 -> bit 2
    // dx=1,dy=2 -> idx 5 -> bit 5
    // dx=0,dy=3 -> idx 6 -> bit 6
    // dx=1,dy=3 -> idx 7 -> bit 7

    // Re-order our subPixels array to match the iteration order in getFrame
    // getFrame iterates: for dy 0..3, for dx 0..1
    // So index = dy * 2 + dx
    // Position (dx=0, dy=0) -> index 0
    // Position (dx=1, dy=0) -> index 1
    // Position (dx=0, dy=1) -> index 2
    // etc.

    // Bit mapping for Braille:
    // Left column (dx=0): dy=0->bit0, dy=1->bit1, dy=2->bit2, dy=3->bit6
    // Right column (dx=1): dy=0->bit3, dy=1->bit4, dy=2->bit5, dy=3->bit7
    const int bit0 = 0x01; // dx=0, dy=0
    const int bit1 = 0x02; // dx=0, dy=1
    const int bit2 = 0x04; // dx=0, dy=2
    const int bit3 = 0x08; // dx=1, dy=0
    const int bit4 = 0x10; // dx=1, dy=1
    const int bit5 = 0x20; // dx=1, dy=2
    const int bit6 = 0x40; // dx=0, dy=3
    const int bit7 = 0x80; // dx=1, dy=3

    // Map from subPixel index to bit
    const indexToBit = [bit0, bit3, bit1, bit4, bit2, bit5, bit6, bit7];

    // Strategy: Use dithering pattern based on average brightness
    // Brightness 0 = no dots, brightness 1 = all dots
    // We threshold each sub-pixel based on a dither pattern

    // Simple ordered dither matrix (8 thresholds for 8 dots)
    // Normalized 0-1 thresholds for when each dot "turns on"
    const thresholds = [
      0.875, // dot 0 (top-left)
      0.625, // dot 3 (top-right)
      0.375, // dot 1 (second-left)
      0.125, // dot 4 (second-right)
      0.750, // dot 2 (third-left)
      0.500, // dot 5 (third-right)
      0.250, // dot 6 (bottom-left)
      1.000, // dot 7 (bottom-right) - only on at full brightness
    ];

    // Fill dots based on brightness and threshold
    for (int i = 0; i < 8; i++) {
      if (subPixels[i] >= 0) {
        // Use the sub-pixel's own brightness
        final b = subPixels[i];
        if (b >= thresholds[i]) {
          dotBits |= indexToBit[i];
        }
      }
    }

    // If no dots were set but we have filled pixels, show at least something
    // at higher brightness levels
    if (dotBits == 0 && avgBrightness > 0.05) {
      // Show a minimal dot pattern for very dark areas
      // Turn on the center-most dots
      dotBits = bit4; // Single center dot
    }

    return 0x2800 + dotBits;
  }
}

/// Internal data for a face being rendered.
class _FaceData {
  final Face face;
  final _ProjectedPoint p0;
  final _ProjectedPoint p1;
  final _ProjectedPoint p2;
  final double depth;
  final double brightness;

  _FaceData({
    required this.face,
    required this.p0,
    required this.p1,
    required this.p2,
    required this.depth,
    required this.brightness,
  });
}
