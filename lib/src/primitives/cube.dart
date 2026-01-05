import '../math/vector3.dart';
import 'face.dart';
import 'shape.dart';

/// A unit cube centered at the origin.
///
/// Vertex layout:
/// ```
/// Front face (z = -0.5):      Back face (z = 0.5):
///     3 ---- 2                    7 ---- 6
///     |      |                    |      |
///     |      |                    |      |
///     0 ---- 1                    4 ---- 5
/// ```
class Cube extends Shape {
  @override
  List<Vector3> get vertices => const [
        // Front face (z = -0.5)
        Vector3(-0.5, -0.5, -0.5), // 0: front bottom left
        Vector3(0.5, -0.5, -0.5), // 1: front bottom right
        Vector3(0.5, 0.5, -0.5), // 2: front top right
        Vector3(-0.5, 0.5, -0.5), // 3: front top left
        // Back face (z = 0.5)
        Vector3(-0.5, -0.5, 0.5), // 4: back bottom left
        Vector3(0.5, -0.5, 0.5), // 5: back bottom right
        Vector3(0.5, 0.5, 0.5), // 6: back top right
        Vector3(-0.5, 0.5, 0.5), // 7: back top left
      ];

  @override
  List<(int, int)> get edges => const [
        // Front face
        (0, 1), (1, 2), (2, 3), (3, 0),
        // Back face
        (4, 5), (5, 6), (6, 7), (7, 4),
        // Connecting edges
        (0, 4), (1, 5), (2, 6), (3, 7),
      ];

  @override
  List<Face> get faces => const [
        // Front face (z = -0.5) - normal points towards -Z
        Face(0, 2, 1),
        Face(0, 3, 2),
        // Back face (z = 0.5) - normal points towards +Z
        Face(4, 5, 6),
        Face(4, 6, 7),
        // Top face (y = 0.5) - normal points towards +Y
        Face(3, 6, 2),
        Face(3, 7, 6),
        // Bottom face (y = -0.5) - normal points towards -Y
        Face(0, 1, 5),
        Face(0, 5, 4),
        // Right face (x = 0.5) - normal points towards +X
        Face(1, 2, 6),
        Face(1, 6, 5),
        // Left face (x = -0.5) - normal points towards -X
        Face(0, 4, 7),
        Face(0, 7, 3),
      ];
}
