import 'dart:math' as math;

import '../math/math.dart';
import '../primitives/face.dart';
import '../primitives/shape.dart';
import 'render_buffer.dart';
import 'renderer.dart' show ProjectedPoint;
import 'shading_style.dart';

/// ASCII characters from dark to light for shading.
const String asciiRamp = ' .:-=+*#%@';

/// Block characters from dark to light.
const String blockRamp = ' ░▒▓█';

/// Renders solid shapes with ASCII shading.
class SolidRenderer {
  /// The width of the render target in characters.
  final int width;

  /// The height of the render target in characters.
  final int height;

  /// The render buffer for drawing.
  final RenderBuffer buffer;

  /// Aspect ratio correction factor for terminal characters.
  final double aspectCorrection;

  /// The depth buffer for z-buffering.
  final List<List<double>> _depthBuffer;

  /// Light direction (normalized).
  final Vector3 lightDirection;

  /// Ambient light intensity (0-1).
  final double ambientLight;

  /// The ASCII ramp to use for shading.
  final String shadingRamp;

  /// Creates a solid renderer with the given dimensions.
  SolidRenderer({
    required this.width,
    required this.height,
    this.aspectCorrection = 2.0,
    Vector3? lightDirection,
    this.ambientLight = 0.1,
    String? shadingRamp,
  })  : buffer = RenderBuffer(width, height),
        _depthBuffer = List.generate(
          height,
          (_) => List.filled(width, double.infinity),
        ),
        lightDirection =
            (lightDirection ?? Vector3(0.5, 0.8, 1.0)).normalized,
        shadingRamp = shadingRamp ?? asciiRamp;

  /// Projects a 3D point to screen coordinates.
  /// Returns null if the point is behind the camera (w <= 0).
  ProjectedPoint? project(Vector3 point, Matrix4 viewProjection) {
    final m = viewProjection.values;

    double x = m[0] * point.x + m[4] * point.y + m[8] * point.z + m[12];
    double y = m[1] * point.x + m[5] * point.y + m[9] * point.z + m[13];
    double z = m[2] * point.x + m[6] * point.y + m[10] * point.z + m[14];
    double w = m[3] * point.x + m[7] * point.y + m[11] * point.z + m[15];

    if (w <= 0) return null;

    double ndcX = x / w;
    double ndcY = y / w;
    double ndcZ = z / w;

    ndcX *= aspectCorrection;

    int screenX = ((ndcX + 1) * 0.5 * width).round();
    int screenY = ((1 - ndcY) * 0.5 * height).round();

    return ProjectedPoint(screenX, screenY, ndcZ);
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
    final projected = <ProjectedPoint?>[];
    for (final v in shape.vertices) {
      projected.add(project(v, mvp));
    }

    // Calculate camera position from view matrix (for back-face culling)
    // For simplicity, we assume camera is looking towards -Z in view space

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
      // Calculate signed area of the 2D triangle
      final signedArea = (p1.x - p0.x) * (p2.y - p0.y) -
          (p2.x - p0.x) * (p1.y - p0.y);

      // Skip back faces (negative signed area means clockwise winding in screen space)
      if (signedArea >= 0) continue;

      // Calculate brightness based on shading style
      double brightness;
      switch (style) {
        case ShadingStyle.solid:
          brightness = 0.7; // Constant brightness
        case ShadingStyle.depth:
          // Average depth, normalized to 0-1 range
          final avgDepth = (p0.depth + p1.depth + p2.depth) / 3;
          // Closer objects (lower depth) are brighter
          brightness = (1 - avgDepth.clamp(-1.0, 1.0)) / 2;
        case ShadingStyle.lit:
          // Lambertian shading with light direction
          final dotProduct = worldNormal.dot(lightDirection);
          brightness = ambientLight + (1 - ambientLight) * math.max(0.0, dotProduct);
        case ShadingStyle.wireframe:
          brightness = 1.0; // Won't reach here, but for completeness
      }

      // Average depth for sorting
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

    // Sort back to front (larger depth = further away = draw first)
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

  /// Renders wireframe only (existing behavior).
  void _renderWireframe(
    Shape shape,
    Matrix4 modelMatrix,
    Matrix4 viewProjection,
  ) {
    final mvp = viewProjection * modelMatrix;

    // Project all vertices
    final projectedVertices = <ProjectedPoint?>[];
    for (final vertex in shape.vertices) {
      projectedVertices.add(project(vertex, mvp));
    }

    // Draw all edges
    for (final edge in shape.edges) {
      final p0 = projectedVertices[edge.$1];
      final p1 = projectedVertices[edge.$2];

      if (p0 == null || p1 == null) continue;

      buffer.drawLine(
        p0.x,
        p0.y,
        p1.x,
        p1.y,
        '*',
        depth0: p0.depth,
        depth1: p1.depth,
      );
    }
  }

  /// Fills a triangle with the given brightness using scanline algorithm.
  void _fillTriangle(
    ProjectedPoint p0,
    ProjectedPoint p1,
    ProjectedPoint p2,
    double brightness,
  ) {
    // Get shading character based on brightness
    final charIndex =
        (brightness * (shadingRamp.length - 1)).round().clamp(0, shadingRamp.length - 1);
    final char = shadingRamp[charIndex];

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

    // Now v0.y <= v1.y <= v2.y

    // Calculate depth at a point using barycentric interpolation
    double depthAt(int x, int y) {
      // Use barycentric coordinates for depth interpolation
      final denom = (v1.y - v2.y) * (v0.x - v2.x) + (v2.x - v1.x) * (v0.y - v2.y);
      if (denom.abs() < 0.0001) return (v0.depth + v1.depth + v2.depth) / 3;

      final w0 = ((v1.y - v2.y) * (x - v2.x) + (v2.x - v1.x) * (y - v2.y)) / denom;
      final w1 = ((v2.y - v0.y) * (x - v2.x) + (v0.x - v2.x) * (y - v2.y)) / denom;
      final w2 = 1 - w0 - w1;

      return w0 * v0.depth + w1 * v1.depth + w2 * v2.depth;
    }

    // Fill the triangle using scanline algorithm
    _fillFlatBottomTriangle(v0, v1, v2, char, depthAt);
    _fillFlatTopTriangle(v0, v1, v2, char, depthAt);
  }

  /// Fills the flat-bottom portion of a triangle (from v0 down to v1-v2 line).
  void _fillFlatBottomTriangle(
    ProjectedPoint v0,
    ProjectedPoint v1,
    ProjectedPoint v2,
    String char,
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
        _setPixelWithDepth(x, scanY, char, depthAt(x, scanY));
      }

      curX1 += invSlope1;
      curX2 += invSlope2;
    }
  }

  /// Fills the flat-top portion of a triangle (from v1 down to v2).
  void _fillFlatTopTriangle(
    ProjectedPoint v0,
    ProjectedPoint v1,
    ProjectedPoint v2,
    String char,
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
        _setPixelWithDepth(x, scanY, char, depthAt(x, scanY));
      }

      curX1 -= invSlope1;
      curX2 -= invSlope2;
    }
  }

  /// Sets a pixel with depth testing.
  void _setPixelWithDepth(int x, int y, String char, double depth) {
    if (x < 0 || x >= width || y < 0 || y >= height) return;

    if (depth < _depthBuffer[y][x]) {
      buffer.buffer[y][x] = char;
      _depthBuffer[y][x] = depth;
    }
  }

  /// Clears the render buffer.
  void clear() {
    buffer.clear();
    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        _depthBuffer[y][x] = double.infinity;
      }
    }
  }

  /// Returns the rendered frame as a string.
  String getFrame() {
    return buffer.render();
  }
}

/// Internal data for a face being rendered.
class _FaceData {
  final Face face;
  final ProjectedPoint p0;
  final ProjectedPoint p1;
  final ProjectedPoint p2;
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
