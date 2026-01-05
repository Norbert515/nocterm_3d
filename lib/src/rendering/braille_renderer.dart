import '../math/math.dart';
import '../particles/particle.dart';
import '../primitives/shape.dart';
import 'braille_buffer.dart';
import 'culling.dart';

/// A high-resolution renderer using Braille characters.
///
/// Each terminal cell is 2x4 sub-pixels, providing 8x more resolution
/// than standard ASCII rendering for smoother wireframes and particles.
class BrailleRenderer {
  /// Terminal width in characters.
  final int width;

  /// Terminal height in characters.
  final int height;

  /// The Braille buffer for drawing.
  final BrailleBuffer buffer;

  /// Aspect ratio correction for terminal characters.
  /// Terminal characters are typically ~2x taller than wide.
  final double aspectCorrection;

  /// Creates a Braille renderer with the given terminal dimensions.
  BrailleRenderer({
    required this.width,
    required this.height,
    this.aspectCorrection = 2.0,
  }) : buffer = BrailleBuffer(width, height);

  /// Projects a 3D point to sub-pixel screen coordinates.
  ///
  /// Returns null if the point is behind the camera (w <= 0).
  ({int x, int y, double depth})? project(
      Vector3 point, Matrix4 viewProjection) {
    // Transform point by viewProjection matrix
    // Matrix is stored in column-major order: [col0, col1, col2, col3]
    final m = viewProjection.values;

    // Multiply point by matrix (assuming column-major storage)
    final x = m[0] * point.x + m[4] * point.y + m[8] * point.z + m[12];
    final y = m[1] * point.x + m[5] * point.y + m[9] * point.z + m[13];
    final z = m[2] * point.x + m[6] * point.y + m[10] * point.z + m[14];
    final w = m[3] * point.x + m[7] * point.y + m[11] * point.z + m[15];

    // Point is behind camera
    if (w <= 0) return null;

    // Perspective divide to NDC
    final ndcX = x / w;
    final ndcY = y / w;

    // Apply aspect correction and map to sub-pixel coordinates
    // buffer.pixelWidth and buffer.pixelHeight give us the sub-pixel dimensions
    final screenX =
        ((ndcX * aspectCorrection + 1) * 0.5 * buffer.pixelWidth).round();
    final screenY =
        ((1 - ndcY) * 0.5 * buffer.pixelHeight).round(); // Flip Y for screen

    return (x: screenX, y: screenY, depth: z / w);
  }

  /// Renders a shape's wireframe.
  void renderShape(Shape shape, Matrix4 modelMatrix, Matrix4 viewProjection) {
    final mvp = _multiplyMatrices(viewProjection, modelMatrix);

    // Project all vertices
    final projected = <({int x, int y, double depth})?>[];
    for (final v in shape.vertices) {
      projected.add(project(v, mvp));
    }

    // Draw edges
    for (final edge in shape.edges) {
      final p0 = projected[edge.$1];
      final p1 = projected[edge.$2];

      // Skip edges where either vertex is behind the camera
      if (p0 != null && p1 != null) {
        buffer.drawLine(
          p0.x,
          p0.y,
          p1.x,
          p1.y,
          depth0: p0.depth,
          depth1: p1.depth,
        );
      }
    }
  }

  /// Renders only the visible edges of a shape (back-face culled wireframe).
  void renderShapeCulled(
      Shape shape, Matrix4 modelMatrix, Matrix4 viewProjection) {
    final mvp = _multiplyMatrices(viewProjection, modelMatrix);

    // Get visible edges based on front-facing triangles
    final visibleEdges = Culling.getVisibleEdges(
      shape,
      mvp,
      buffer.pixelWidth,
      buffer.pixelHeight,
      aspectCorrection,
    );

    // Project all vertices
    final projected = <({int x, int y, double depth})?>[];
    for (final v in shape.vertices) {
      projected.add(project(v, mvp));
    }

    // Draw only visible edges
    for (final edge in visibleEdges) {
      final p0 = projected[edge.$1];
      final p1 = projected[edge.$2];

      // Skip edges where either vertex is behind the camera
      if (p0 != null && p1 != null) {
        buffer.drawLine(
          p0.x,
          p0.y,
          p1.x,
          p1.y,
          depth0: p0.depth,
          depth1: p1.depth,
        );
      }
    }
  }

  /// Renders particles.
  void renderParticles(List<Particle> particles, Matrix4 viewProjection) {
    for (final p in particles) {
      final proj = project(p.position, viewProjection);
      if (proj != null) {
        buffer.setPixel(proj.x, proj.y, depth: proj.depth);
      }
    }
  }

  /// Clears the render buffer.
  void clear() => buffer.clear();

  /// Returns the rendered frame as a string.
  String getFrame() => buffer.render();

  /// Multiplies two 4x4 matrices (a * b).
  Matrix4 _multiplyMatrices(Matrix4 a, Matrix4 b) {
    final am = a.values;
    final bm = b.values;
    final result = List<double>.filled(16, 0);

    // Column-major multiplication
    for (int col = 0; col < 4; col++) {
      for (int row = 0; row < 4; row++) {
        double sum = 0;
        for (int k = 0; k < 4; k++) {
          sum += am[row + k * 4] * bm[k + col * 4];
        }
        result[row + col * 4] = sum;
      }
    }

    return Matrix4(result);
  }
}
