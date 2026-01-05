/// Different shading styles for solid rendering.
enum ShadingStyle {
  /// Wireframe only (existing behavior).
  wireframe,

  /// Solid faces with flat shading (one brightness per face).
  solid,

  /// Solid with depth-based shading (closer = brighter).
  depth,

  /// Solid with normal-based lighting.
  lit,
}
