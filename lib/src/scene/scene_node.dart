import '../math/math.dart';
import '../primitives/shape.dart';

/// A static identity matrix for use as default transform.
final Matrix4 _identity = Matrix4.identity();

/// A node in the scene graph.
class SceneNode {
  final Shape? shape;
  final Matrix4 transform;
  final List<SceneNode> children;

  /// Creates a scene node with optional shape, transform, and children.
  SceneNode({
    this.shape,
    Matrix4? transform,
    this.children = const [],
  }) : transform = transform ?? _identity;

  /// Creates a node with a shape.
  factory SceneNode.shape(Shape shape, {Matrix4? transform}) {
    return SceneNode(
      shape: shape,
      transform: transform,
    );
  }

  /// Creates a group node (no shape, just children).
  factory SceneNode.group(List<SceneNode> children, {Matrix4? transform}) {
    return SceneNode(
      children: children,
      transform: transform,
    );
  }

  /// Creates a node with a translation transform.
  factory SceneNode.translated(
    double x,
    double y,
    double z, {
    Shape? shape,
    List<SceneNode>? children,
  }) {
    return SceneNode(
      shape: shape,
      transform: Matrix4.translation(x, y, z),
      children: children ?? const [],
    );
  }

  /// Creates a node with rotation transforms (X, Y, Z in radians).
  factory SceneNode.rotated(
    double rx,
    double ry,
    double rz, {
    Shape? shape,
    List<SceneNode>? children,
  }) {
    // Combine rotations: Rz * Ry * Rx
    final rotation = Matrix4.rotationZ(rz) *
        Matrix4.rotationY(ry) *
        Matrix4.rotationX(rx);
    return SceneNode(
      shape: shape,
      transform: rotation,
      children: children ?? const [],
    );
  }

  /// Creates a node with a scale transform.
  factory SceneNode.scaled(
    double sx,
    double sy,
    double sz, {
    Shape? shape,
    List<SceneNode>? children,
  }) {
    return SceneNode(
      shape: shape,
      transform: Matrix4.scale(sx, sy, sz),
      children: children ?? const [],
    );
  }

  /// Creates a copy with modified parameters.
  SceneNode copyWith({
    Shape? shape,
    Matrix4? transform,
    List<SceneNode>? children,
  }) {
    return SceneNode(
      shape: shape ?? this.shape,
      transform: transform ?? this.transform,
      children: children ?? this.children,
    );
  }
}
