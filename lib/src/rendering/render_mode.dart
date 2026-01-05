/// The rendering mode for 3D scenes.
enum RenderMode {
  /// Standard ASCII wireframe using characters like '*'.
  ascii,

  /// High-resolution wireframe using Braille Unicode characters (2x4 sub-pixels per char).
  /// Provides smoother wireframes and better particle rendering.
  braille,

  /// ASCII wireframe with back-face culling (only visible edges).
  asciiCulled,

  /// Braille wireframe with back-face culling (only visible edges).
  brailleCulled,

  /// Solid ASCII with shading using ASCII character density.
  solidAscii,

  /// Solid Braille with density shading using Braille dot patterns.
  solidBraille,
}
