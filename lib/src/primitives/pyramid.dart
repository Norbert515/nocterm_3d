import '../math/vector3.dart';
import 'shape.dart';

/// A pyramid with a square base, centered at the origin.
///
/// The base is in the XZ plane at Y = -0.5, and the apex is at Y = 0.5.
class Pyramid extends Shape {
  @override
  List<Vector3> get vertices => const [
        // Base corners (in XZ plane at y = -0.5)
        Vector3(-0.5, -0.5, -0.5), // 0: front-left
        Vector3(0.5, -0.5, -0.5), // 1: front-right
        Vector3(0.5, -0.5, 0.5), // 2: back-right
        Vector3(-0.5, -0.5, 0.5), // 3: back-left
        // Apex
        Vector3(0, 0.5, 0), // 4: top
      ];

  @override
  List<(int, int)> get edges => const [
        // Base edges (square)
        (0, 1),
        (1, 2),
        (2, 3),
        (3, 0),
        // Side edges (from base corners to apex)
        (0, 4),
        (1, 4),
        (2, 4),
        (3, 4),
      ];
}
