import '../math/math.dart';
import '../primitives/shape.dart';

/// Helper class for back-face culling operations.
class Culling {
  /// Returns edges that belong to at least one front-facing triangle.
  /// Uses screen-space winding order for culling.
  ///
  /// [shape] - The shape to get visible edges from.
  /// [mvp] - The combined model-view-projection matrix.
  /// [screenWidth] - Width of the screen in units (characters or sub-pixels).
  /// [screenHeight] - Height of the screen in units.
  /// [aspectCorrection] - Aspect ratio correction factor.
  static List<(int, int)> getVisibleEdges(
    Shape shape,
    Matrix4 mvp,
    int screenWidth,
    int screenHeight,
    double aspectCorrection,
  ) {
    final m = mvp.values;

    // Project all vertices to screen space
    final projected = <({double x, double y, double z, double w})?>[];
    for (final v in shape.vertices) {
      // Transform point by MVP matrix
      final x = m[0] * v.x + m[4] * v.y + m[8] * v.z + m[12];
      final y = m[1] * v.x + m[5] * v.y + m[9] * v.z + m[13];
      final z = m[2] * v.x + m[6] * v.y + m[10] * v.z + m[14];
      final w = m[3] * v.x + m[7] * v.y + m[11] * v.z + m[15];

      // Point is behind camera
      if (w <= 0) {
        projected.add(null);
        continue;
      }

      // Perspective divide to NDC
      final ndcX = x / w;
      final ndcY = y / w;
      final ndcZ = z / w;

      // Apply aspect correction and map to screen coordinates
      final screenX = (ndcX * aspectCorrection + 1) * 0.5 * screenWidth;
      // Flip Y for screen coordinates (screen Y grows downward)
      final screenY = (1 - ndcY) * 0.5 * screenHeight;

      projected.add((x: screenX, y: screenY, z: ndcZ, w: w));
    }

    // Collect visible edges from front-facing triangles
    final visibleEdges = <(int, int)>{};

    for (final face in shape.faces) {
      final p0 = projected[face.v0];
      final p1 = projected[face.v1];
      final p2 = projected[face.v2];

      // Skip faces with any vertex behind camera
      if (p0 == null || p1 == null || p2 == null) continue;

      // Calculate signed area (2x area of triangle) using screen coordinates
      // Positive = counter-clockwise on screen
      // Note: With Y inverted (screen coords), front-facing is clockwise in world
      // which becomes counter-clockwise in screen space
      final signedArea =
          (p1.x - p0.x) * (p2.y - p0.y) - (p2.x - p0.x) * (p1.y - p0.y);

      // Front-facing if signedArea < 0 (clockwise on screen after Y inversion)
      // The sign depends on your coordinate system - test and adjust if needed
      if (signedArea < 0) {
        // Add all three edges of this face
        visibleEdges.add(_normalizeEdge(face.v0, face.v1));
        visibleEdges.add(_normalizeEdge(face.v1, face.v2));
        visibleEdges.add(_normalizeEdge(face.v2, face.v0));
      }
    }

    return visibleEdges.toList();
  }

  /// Normalizes an edge so (a,b) and (b,a) are the same.
  static (int, int) _normalizeEdge(int a, int b) => a < b ? (a, b) : (b, a);
}
