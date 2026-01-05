import '../math/vector3.dart';
import 'face.dart';

/// Base class for all 3D shapes.
abstract class Shape {
  /// The vertices that make up this shape.
  List<Vector3> get vertices;

  /// The edges connecting vertices (pairs of vertex indices).
  List<(int, int)> get edges;

  /// Faces for solid rendering (triangles).
  /// Default returns empty - wireframe only shapes.
  List<Face> get faces => const [];
}
