import '../math/math.dart';
import '../rendering/rendering.dart';
import 'camera.dart';
import 'particle_scene_node.dart';
import 'scene_node.dart';

/// A complete 3D scene with camera and nodes.
class Scene {
  final Camera camera;
  final List<SceneNode> nodes;
  final List<ParticleSceneNode> particleNodes;
  final String wireframeChar;

  /// The rendering mode to use.
  final RenderMode renderMode;

  /// The shading style for solid rendering modes.
  final ShadingStyle shadingStyle;

  /// Light direction for lit shading (will be normalized).
  final Vector3? lightDirection;

  const Scene({
    required this.camera,
    this.nodes = const [],
    this.particleNodes = const [],
    this.wireframeChar = '*',
    this.renderMode = RenderMode.braille,
    this.shadingStyle = ShadingStyle.lit,
    this.lightDirection,
  });

  /// Renders the scene to a string.
  String render(int width, int height) {
    // Calculate aspect ratio (accounting for terminal character proportions)
    final aspectRatio = width / height;

    // Get view-projection matrix from camera
    final viewProjection = camera.viewProjectionMatrix(aspectRatio);

    switch (renderMode) {
      case RenderMode.braille:
        return _renderWithBraille(width, height, viewProjection);
      case RenderMode.ascii:
        return _renderWithAscii(width, height, viewProjection);
      case RenderMode.asciiCulled:
        return _renderWithAsciiCulled(width, height, viewProjection);
      case RenderMode.brailleCulled:
        return _renderWithBrailleCulled(width, height, viewProjection);
      case RenderMode.solidAscii:
        return _renderWithSolidAscii(width, height, viewProjection);
      case RenderMode.solidBraille:
        return _renderWithSolidBraille(width, height, viewProjection);
    }
  }

  /// Renders using the high-resolution Braille renderer.
  String _renderWithBraille(int width, int height, Matrix4 viewProjection) {
    final renderer = BrailleRenderer(
      width: width,
      height: height,
    );

    // Recursively render all nodes with accumulated transforms
    for (final node in nodes) {
      _renderNodeBraille(renderer, node, Matrix4.identity(), viewProjection);
    }

    // Render particle systems
    for (final particleNode in particleNodes) {
      _renderParticleNodeBraille(renderer, particleNode, viewProjection);
    }

    return renderer.getFrame();
  }

  /// Renders using the standard ASCII renderer.
  String _renderWithAscii(int width, int height, Matrix4 viewProjection) {
    final renderer = Renderer(
      width: width,
      height: height,
      wireframeChar: wireframeChar,
    );

    // Recursively render all nodes with accumulated transforms
    for (final node in nodes) {
      _renderNode(renderer, node, Matrix4.identity(), viewProjection);
    }

    // Render particle systems
    for (final particleNode in particleNodes) {
      _renderParticleNode(renderer, particleNode, viewProjection);
    }

    return renderer.getFrame();
  }

  /// Renders using ASCII with back-face culling (only visible edges).
  String _renderWithAsciiCulled(int width, int height, Matrix4 viewProjection) {
    final renderer = Renderer(
      width: width,
      height: height,
      wireframeChar: wireframeChar,
    );

    // Recursively render all nodes with accumulated transforms using culled rendering
    for (final node in nodes) {
      _renderNodeCulled(renderer, node, Matrix4.identity(), viewProjection);
    }

    // Render particle systems
    for (final particleNode in particleNodes) {
      _renderParticleNode(renderer, particleNode, viewProjection);
    }

    return renderer.getFrame();
  }

  /// Renders using Braille with back-face culling (only visible edges).
  String _renderWithBrailleCulled(
      int width, int height, Matrix4 viewProjection) {
    final renderer = BrailleRenderer(
      width: width,
      height: height,
    );

    // Recursively render all nodes with accumulated transforms using culled rendering
    for (final node in nodes) {
      _renderNodeBrailleCulled(
          renderer, node, Matrix4.identity(), viewProjection);
    }

    // Render particle systems
    for (final particleNode in particleNodes) {
      _renderParticleNodeBraille(renderer, particleNode, viewProjection);
    }

    return renderer.getFrame();
  }

  /// Renders using the solid ASCII renderer with shading.
  String _renderWithSolidAscii(int width, int height, Matrix4 viewProjection) {
    final renderer = SolidRenderer(
      width: width,
      height: height,
      lightDirection: lightDirection,
    );

    // Recursively render all nodes with accumulated transforms
    for (final node in nodes) {
      _renderNodeSolid(renderer, node, Matrix4.identity(), viewProjection);
    }

    return renderer.getFrame();
  }

  /// Renders using the solid Braille renderer with shading.
  String _renderWithSolidBraille(
      int width, int height, Matrix4 viewProjection) {
    final renderer = BrailleSolidRenderer(
      width: width,
      height: height,
      lightDirection: lightDirection,
    );

    // Recursively render all nodes with accumulated transforms
    for (final node in nodes) {
      _renderNodeSolidBraille(
          renderer, node, Matrix4.identity(), viewProjection);
    }

    return renderer.getFrame();
  }

  /// Renders a particle scene node.
  void _renderParticleNode(
    Renderer renderer,
    ParticleSceneNode particleNode,
    Matrix4 viewProjection,
  ) {
    // Transform particles by the node's transform
    final particles = particleNode.particleSystem.particles;
    final transform = particleNode.transform;

    // For each particle, transform its position and render
    for (final particle in particles) {
      // Transform particle position by the node's transform
      final worldPos = _transformPoint(particle.position, transform);

      // Project and render
      final projected = renderer.project(worldPos, viewProjection);
      if (projected != null) {
        renderer.buffer.setPixel(
          projected.x,
          projected.y,
          particle.char,
          depth: projected.depth,
        );
      }
    }
  }

  /// Transforms a point by a matrix.
  Vector3 _transformPoint(Vector3 point, Matrix4 matrix) {
    final m = matrix.values;
    final x = m[0] * point.x + m[4] * point.y + m[8] * point.z + m[12];
    final y = m[1] * point.x + m[5] * point.y + m[9] * point.z + m[13];
    final z = m[2] * point.x + m[6] * point.y + m[10] * point.z + m[14];
    final w = m[3] * point.x + m[7] * point.y + m[11] * point.z + m[15];
    if (w != 0 && w != 1) {
      return Vector3(x / w, y / w, z / w);
    }
    return Vector3(x, y, z);
  }

  /// Recursively renders a node and its children with accumulated transform.
  void _renderNode(
    Renderer renderer,
    SceneNode node,
    Matrix4 parentTransform,
    Matrix4 viewProjection,
  ) {
    // Accumulate transform: parent * local
    final worldTransform = parentTransform * node.transform;

    // Render the shape if present
    if (node.shape != null) {
      renderer.renderShape(node.shape!, worldTransform, viewProjection);
    }

    // Render children with accumulated transform
    for (final child in node.children) {
      _renderNode(renderer, child, worldTransform, viewProjection);
    }
  }

  /// Recursively renders a node using the Braille renderer.
  void _renderNodeBraille(
    BrailleRenderer renderer,
    SceneNode node,
    Matrix4 parentTransform,
    Matrix4 viewProjection,
  ) {
    // Accumulate transform: parent * local
    final worldTransform = parentTransform * node.transform;

    // Render the shape if present
    if (node.shape != null) {
      renderer.renderShape(node.shape!, worldTransform, viewProjection);
    }

    // Render children with accumulated transform
    for (final child in node.children) {
      _renderNodeBraille(renderer, child, worldTransform, viewProjection);
    }
  }

  /// Recursively renders a node with back-face culling.
  void _renderNodeCulled(
    Renderer renderer,
    SceneNode node,
    Matrix4 parentTransform,
    Matrix4 viewProjection,
  ) {
    // Accumulate transform: parent * local
    final worldTransform = parentTransform * node.transform;

    // Render the shape if present using culled rendering
    if (node.shape != null) {
      renderer.renderShapeCulled(node.shape!, worldTransform, viewProjection);
    }

    // Render children with accumulated transform
    for (final child in node.children) {
      _renderNodeCulled(renderer, child, worldTransform, viewProjection);
    }
  }

  /// Recursively renders a node using Braille with back-face culling.
  void _renderNodeBrailleCulled(
    BrailleRenderer renderer,
    SceneNode node,
    Matrix4 parentTransform,
    Matrix4 viewProjection,
  ) {
    // Accumulate transform: parent * local
    final worldTransform = parentTransform * node.transform;

    // Render the shape if present using culled rendering
    if (node.shape != null) {
      renderer.renderShapeCulled(node.shape!, worldTransform, viewProjection);
    }

    // Render children with accumulated transform
    for (final child in node.children) {
      _renderNodeBrailleCulled(renderer, child, worldTransform, viewProjection);
    }
  }

  /// Recursively renders a node using the solid ASCII renderer.
  void _renderNodeSolid(
    SolidRenderer renderer,
    SceneNode node,
    Matrix4 parentTransform,
    Matrix4 viewProjection,
  ) {
    // Accumulate transform: parent * local
    final worldTransform = parentTransform * node.transform;

    // Render the shape if present
    if (node.shape != null) {
      renderer.renderShape(
          node.shape!, worldTransform, viewProjection, shadingStyle);
    }

    // Render children with accumulated transform
    for (final child in node.children) {
      _renderNodeSolid(renderer, child, worldTransform, viewProjection);
    }
  }

  /// Recursively renders a node using the solid Braille renderer.
  void _renderNodeSolidBraille(
    BrailleSolidRenderer renderer,
    SceneNode node,
    Matrix4 parentTransform,
    Matrix4 viewProjection,
  ) {
    // Accumulate transform: parent * local
    final worldTransform = parentTransform * node.transform;

    // Render the shape if present
    if (node.shape != null) {
      renderer.renderShape(
          node.shape!, worldTransform, viewProjection, shadingStyle);
    }

    // Render children with accumulated transform
    for (final child in node.children) {
      _renderNodeSolidBraille(renderer, child, worldTransform, viewProjection);
    }
  }

  /// Renders a particle scene node using the Braille renderer.
  void _renderParticleNodeBraille(
    BrailleRenderer renderer,
    ParticleSceneNode particleNode,
    Matrix4 viewProjection,
  ) {
    // Transform particles by the node's transform
    final particles = particleNode.particleSystem.particles;
    final transform = particleNode.transform;

    // For each particle, transform its position and render
    for (final particle in particles) {
      // Transform particle position by the node's transform
      final worldPos = _transformPoint(particle.position, transform);

      // Project and render
      final projected = renderer.project(worldPos, viewProjection);
      if (projected != null) {
        renderer.buffer.setPixel(
          projected.x,
          projected.y,
          depth: projected.depth,
        );
      }
    }
  }

  /// Creates a copy with modified parameters.
  Scene copyWith({
    Camera? camera,
    List<SceneNode>? nodes,
    List<ParticleSceneNode>? particleNodes,
    String? wireframeChar,
    RenderMode? renderMode,
    ShadingStyle? shadingStyle,
    Vector3? lightDirection,
  }) {
    return Scene(
      camera: camera ?? this.camera,
      nodes: nodes ?? this.nodes,
      particleNodes: particleNodes ?? this.particleNodes,
      wireframeChar: wireframeChar ?? this.wireframeChar,
      renderMode: renderMode ?? this.renderMode,
      shadingStyle: shadingStyle ?? this.shadingStyle,
      lightDirection: lightDirection ?? this.lightDirection,
    );
  }
}
