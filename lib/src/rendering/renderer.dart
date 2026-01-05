import '../math/math.dart';
import '../particles/particle.dart';
import '../primitives/shape.dart';
import 'culling.dart';
import 'render_buffer.dart';

/// A 2D point with depth information for rendering.
class ProjectedPoint {
  final int x;
  final int y;
  final double depth;

  const ProjectedPoint(this.x, this.y, this.depth);
}

/// The ASCII renderer for 3D scenes.
class Renderer {
  /// The width of the render target in characters.
  final int width;

  /// The height of the render target in characters.
  final int height;

  /// The render buffer for drawing.
  final RenderBuffer buffer;

  /// Aspect ratio correction factor for terminal characters.
  /// Terminal characters are typically ~2x taller than wide.
  final double aspectCorrection;

  /// The default character used for wireframe rendering.
  final String wireframeChar;

  /// Creates a renderer with the given dimensions.
  Renderer({
    required this.width,
    required this.height,
    this.aspectCorrection = 2.0,
    this.wireframeChar = '*',
  }) : buffer = RenderBuffer(width, height);

  /// Projects a 3D point to 2D screen coordinates.
  /// Returns null if the point is behind the camera (w <= 0).
  ProjectedPoint? project(Vector3 point, Matrix4 viewProjection) {
    // Transform point by viewProjection matrix
    // Matrix is stored in column-major order: [col0, col1, col2, col3]
    // Each column has 4 elements
    final m = viewProjection.values;

    // Multiply point by matrix (assuming column-major storage)
    // result = M * [x, y, z, 1]
    double x = m[0] * point.x + m[4] * point.y + m[8] * point.z + m[12];
    double y = m[1] * point.x + m[5] * point.y + m[9] * point.z + m[13];
    double z = m[2] * point.x + m[6] * point.y + m[10] * point.z + m[14];
    double w = m[3] * point.x + m[7] * point.y + m[11] * point.z + m[15];

    // Point is behind camera
    if (w <= 0) return null;

    // Perspective divide
    double ndcX = x / w;
    double ndcY = y / w;
    double ndcZ = z / w; // Used for depth

    // Apply aspect correction to X (terminal chars are taller than wide)
    ndcX *= aspectCorrection;

    // Map from NDC [-1, 1] to screen coordinates [0, width] and [0, height]
    // Note: Y is inverted because screen Y grows downward
    int screenX = ((ndcX + 1) * 0.5 * width).round();
    int screenY = ((1 - ndcY) * 0.5 * height).round();

    return ProjectedPoint(screenX, screenY, ndcZ);
  }

  /// Renders a shape with the given model and view-projection matrices.
  void renderShape(Shape shape, Matrix4 modelMatrix, Matrix4 viewProjection) {
    // Combine model and view-projection
    final mvp = _multiplyMatrices(viewProjection, modelMatrix);

    // Project all vertices
    final projectedVertices = <ProjectedPoint?>[];
    for (final vertex in shape.vertices) {
      projectedVertices.add(project(vertex, mvp));
    }

    // Draw all edges
    for (final edge in shape.edges) {
      final p0 = projectedVertices[edge.$1];
      final p1 = projectedVertices[edge.$2];

      // Skip edges where either vertex is behind the camera
      if (p0 == null || p1 == null) continue;

      buffer.drawLine(
        p0.x,
        p0.y,
        p1.x,
        p1.y,
        wireframeChar,
        depth0: p0.depth,
        depth1: p1.depth,
      );
    }
  }

  /// Renders only the visible edges of a shape (back-face culled wireframe).
  void renderShapeCulled(
      Shape shape, Matrix4 modelMatrix, Matrix4 viewProjection) {
    // Combine model and view-projection
    final mvp = _multiplyMatrices(viewProjection, modelMatrix);

    // Get visible edges based on front-facing triangles
    final visibleEdges = Culling.getVisibleEdges(
      shape,
      mvp,
      width,
      height,
      aspectCorrection,
    );

    // Project all vertices
    final projectedVertices = <ProjectedPoint?>[];
    for (final vertex in shape.vertices) {
      projectedVertices.add(project(vertex, mvp));
    }

    // Draw only visible edges
    for (final edge in visibleEdges) {
      final p0 = projectedVertices[edge.$1];
      final p1 = projectedVertices[edge.$2];

      // Skip edges where either vertex is behind the camera
      if (p0 == null || p1 == null) continue;

      buffer.drawLine(
        p0.x,
        p0.y,
        p1.x,
        p1.y,
        wireframeChar,
        depth0: p0.depth,
        depth1: p1.depth,
      );
    }
  }

  /// Clears the render buffer.
  void clear() {
    buffer.clear();
  }

  /// Returns the rendered frame as a string.
  String getFrame() {
    return buffer.render();
  }

  /// Renders particles with the given view-projection matrix.
  void renderParticles(List<Particle> particles, Matrix4 viewProjection) {
    for (final p in particles) {
      final projected = project(p.position, viewProjection);
      if (projected != null) {
        // Use particle's char
        buffer.setPixel(
          projected.x,
          projected.y,
          p.char,
          depth: projected.depth,
        );
      }
    }
  }

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
