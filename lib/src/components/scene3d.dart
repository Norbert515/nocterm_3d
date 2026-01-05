import 'package:nocterm/nocterm.dart' hide Matrix4;
import 'package:nocterm/src/framework/terminal_canvas.dart';

import '../math/math.dart' as math3d;
import '../rendering/braille_renderer.dart';
import '../rendering/braille_solid_renderer.dart';
import '../rendering/render_mode.dart';
import '../rendering/renderer.dart';
import '../rendering/shading_style.dart';
import '../rendering/solid_renderer.dart';
import '../scene/camera.dart';
import '../scene/particle_scene_node.dart';
import '../scene/scene_node.dart';

/// A Nocterm component that renders a 3D scene.
class Scene3D extends StatelessComponent {
  /// The camera used to view the scene.
  final Camera camera;

  /// The scene nodes to render.
  final List<SceneNode> nodes;

  /// The particle scene nodes to render.
  final List<ParticleSceneNode> particleNodes;

  /// The character used for wireframe rendering (only used in ASCII mode).
  final String wireframeChar;

  /// The rendering mode to use.
  final RenderMode renderMode;

  /// The shading style for solid rendering modes.
  final ShadingStyle shadingStyle;

  /// Light direction for lit shading (will be normalized).
  final math3d.Vector3? lightDirection;

  const Scene3D({
    super.key,
    required this.camera,
    this.nodes = const [],
    this.particleNodes = const [],
    this.wireframeChar = '*',
    this.renderMode = RenderMode.braille,
    this.shadingStyle = ShadingStyle.lit,
    this.lightDirection,
  });

  @override
  Component build(BuildContext context) {
    return _Scene3DLayout(
      camera: camera,
      nodes: nodes,
      particleNodes: particleNodes,
      wireframeChar: wireframeChar,
      renderMode: renderMode,
      shadingStyle: shadingStyle,
      lightDirection: lightDirection,
    );
  }
}

/// Internal component that handles layout and rendering.
class _Scene3DLayout extends SingleChildRenderObjectComponent {
  final Camera camera;
  final List<SceneNode> nodes;
  final List<ParticleSceneNode> particleNodes;
  final String wireframeChar;
  final RenderMode renderMode;
  final ShadingStyle shadingStyle;
  final math3d.Vector3? lightDirection;

  const _Scene3DLayout({
    required this.camera,
    required this.nodes,
    required this.particleNodes,
    required this.wireframeChar,
    required this.renderMode,
    required this.shadingStyle,
    this.lightDirection,
  });

  @override
  RenderObject createRenderObject(BuildContext context) {
    return _Scene3DRenderObject(
      camera: camera,
      nodes: nodes,
      particleNodes: particleNodes,
      wireframeChar: wireframeChar,
      renderMode: renderMode,
      shadingStyle: shadingStyle,
      lightDirection: lightDirection,
    );
  }

  @override
  void updateRenderObject(
      BuildContext context, _Scene3DRenderObject renderObject) {
    renderObject
      ..camera = camera
      ..nodes = nodes
      ..particleNodes = particleNodes
      ..wireframeChar = wireframeChar
      ..renderMode = renderMode
      ..shadingStyle = shadingStyle
      ..lightDirection = lightDirection;
  }
}

/// Custom render object for 3D scene rendering.
class _Scene3DRenderObject extends RenderObject {
  Camera _camera;
  List<SceneNode> _nodes;
  List<ParticleSceneNode> _particleNodes;
  String _wireframeChar;
  RenderMode _renderMode;
  ShadingStyle _shadingStyle;
  math3d.Vector3? _lightDirection;

  _Scene3DRenderObject({
    required Camera camera,
    required List<SceneNode> nodes,
    required List<ParticleSceneNode> particleNodes,
    required String wireframeChar,
    required RenderMode renderMode,
    required ShadingStyle shadingStyle,
    math3d.Vector3? lightDirection,
  })  : _camera = camera,
        _nodes = nodes,
        _particleNodes = particleNodes,
        _wireframeChar = wireframeChar,
        _renderMode = renderMode,
        _shadingStyle = shadingStyle,
        _lightDirection = lightDirection;

  Camera get camera => _camera;
  set camera(Camera value) {
    if (_camera != value) {
      _camera = value;
      markNeedsPaint();
    }
  }

  List<SceneNode> get nodes => _nodes;
  set nodes(List<SceneNode> value) {
    if (_nodes != value) {
      _nodes = value;
      markNeedsPaint();
    }
  }

  List<ParticleSceneNode> get particleNodes => _particleNodes;
  set particleNodes(List<ParticleSceneNode> value) {
    if (_particleNodes != value) {
      _particleNodes = value;
      markNeedsPaint();
    }
  }

  String get wireframeChar => _wireframeChar;
  set wireframeChar(String value) {
    if (_wireframeChar != value) {
      _wireframeChar = value;
      markNeedsPaint();
    }
  }

  RenderMode get renderMode => _renderMode;
  set renderMode(RenderMode value) {
    if (_renderMode != value) {
      _renderMode = value;
      markNeedsPaint();
    }
  }

  ShadingStyle get shadingStyle => _shadingStyle;
  set shadingStyle(ShadingStyle value) {
    if (_shadingStyle != value) {
      _shadingStyle = value;
      markNeedsPaint();
    }
  }

  math3d.Vector3? get lightDirection => _lightDirection;
  set lightDirection(math3d.Vector3? value) {
    if (_lightDirection != value) {
      _lightDirection = value;
      markNeedsPaint();
    }
  }

  @override
  void performLayout() {
    // Take all available space from constraints
    size = Size(constraints.maxWidth, constraints.maxHeight);
  }

  @override
  void paint(TerminalCanvas canvas, Offset offset) {
    super.paint(canvas, offset);

    final width = size.width.toInt();
    final height = size.height.toInt();

    if (width <= 0 || height <= 0) return;

    // Calculate aspect ratio (accounting for terminal character aspect)
    // Terminal chars are ~2x taller than wide, which is handled by Renderer
    final aspectRatio = width / height;

    // Get view-projection matrix
    final viewProjection = _camera.viewProjectionMatrix(aspectRatio);

    // Render based on mode
    final String frame;
    switch (_renderMode) {
      case RenderMode.braille:
        frame = _paintWithBraille(width, height, viewProjection);
      case RenderMode.ascii:
        frame = _paintWithAscii(width, height, viewProjection);
      case RenderMode.asciiCulled:
        frame = _paintWithAsciiCulled(width, height, viewProjection);
      case RenderMode.brailleCulled:
        frame = _paintWithBrailleCulled(width, height, viewProjection);
      case RenderMode.solidAscii:
        frame = _paintWithSolidAscii(width, height, viewProjection);
      case RenderMode.solidBraille:
        frame = _paintWithSolidBraille(width, height, viewProjection);
    }

    // Determine empty character based on mode
    final emptyChar = (_renderMode == RenderMode.braille ||
            _renderMode == RenderMode.brailleCulled ||
            _renderMode == RenderMode.solidBraille)
        ? '\u2800'
        : ' ';

    // Draw to terminal canvas
    final lines = frame.split('\n');
    for (int y = 0; y < lines.length && y < height; y++) {
      final line = lines[y];
      for (int x = 0; x < line.length && x < width; x++) {
        final char = line[x];
        if (char != emptyChar) {
          canvas.drawText(
            Offset(offset.dx + x, offset.dy + y),
            char,
          );
        }
      }
    }
  }

  /// Paints using the Braille renderer.
  String _paintWithBraille(
      int width, int height, math3d.Matrix4 viewProjection) {
    final renderer = BrailleRenderer(
      width: width,
      height: height,
    );

    renderer.clear();
    for (final node in _nodes) {
      _renderNodeBraille(
          renderer, node, viewProjection, math3d.Matrix4.identity());
    }

    for (final particleNode in _particleNodes) {
      _renderParticleNodeBraille(renderer, particleNode, viewProjection);
    }

    return renderer.getFrame();
  }

  /// Paints using the ASCII renderer.
  String _paintWithAscii(int width, int height, math3d.Matrix4 viewProjection) {
    final renderer = Renderer(
      width: width,
      height: height,
      wireframeChar: _wireframeChar,
    );

    renderer.clear();
    for (final node in _nodes) {
      _renderNode(renderer, node, viewProjection, math3d.Matrix4.identity());
    }

    for (final particleNode in _particleNodes) {
      _renderParticleNode(renderer, particleNode, viewProjection);
    }

    return renderer.getFrame();
  }

  /// Paints using the ASCII renderer with back-face culling.
  String _paintWithAsciiCulled(
      int width, int height, math3d.Matrix4 viewProjection) {
    final renderer = Renderer(
      width: width,
      height: height,
      wireframeChar: _wireframeChar,
    );

    renderer.clear();
    for (final node in _nodes) {
      _renderNodeCulled(
          renderer, node, viewProjection, math3d.Matrix4.identity());
    }

    for (final particleNode in _particleNodes) {
      _renderParticleNode(renderer, particleNode, viewProjection);
    }

    return renderer.getFrame();
  }

  /// Paints using the Braille renderer with back-face culling.
  String _paintWithBrailleCulled(
      int width, int height, math3d.Matrix4 viewProjection) {
    final renderer = BrailleRenderer(
      width: width,
      height: height,
    );

    renderer.clear();
    for (final node in _nodes) {
      _renderNodeBrailleCulled(
          renderer, node, viewProjection, math3d.Matrix4.identity());
    }

    for (final particleNode in _particleNodes) {
      _renderParticleNodeBraille(renderer, particleNode, viewProjection);
    }

    return renderer.getFrame();
  }

  /// Paints using the solid ASCII renderer with shading.
  String _paintWithSolidAscii(
      int width, int height, math3d.Matrix4 viewProjection) {
    final renderer = SolidRenderer(
      width: width,
      height: height,
      lightDirection: _lightDirection,
    );

    renderer.clear();
    for (final node in _nodes) {
      _renderNodeSolid(
          renderer, node, viewProjection, math3d.Matrix4.identity());
    }

    return renderer.getFrame();
  }

  /// Paints using the solid Braille renderer with shading.
  String _paintWithSolidBraille(
      int width, int height, math3d.Matrix4 viewProjection) {
    final renderer = BrailleSolidRenderer(
      width: width,
      height: height,
      lightDirection: _lightDirection,
    );

    renderer.clear();
    for (final node in _nodes) {
      _renderNodeSolidBraille(
          renderer, node, viewProjection, math3d.Matrix4.identity());
    }

    return renderer.getFrame();
  }

  /// Recursively renders a scene node and its children using ASCII.
  void _renderNode(
    Renderer renderer,
    SceneNode node,
    math3d.Matrix4 viewProjection,
    math3d.Matrix4 parentTransform,
  ) {
    // Combine parent transform with node's transform
    final worldTransform = parentTransform * node.transform;

    // Render the shape if present
    if (node.shape != null) {
      renderer.renderShape(node.shape!, worldTransform, viewProjection);
    }

    // Render children
    for (final child in node.children) {
      _renderNode(renderer, child, viewProjection, worldTransform);
    }
  }

  /// Recursively renders a scene node and its children using Braille.
  void _renderNodeBraille(
    BrailleRenderer renderer,
    SceneNode node,
    math3d.Matrix4 viewProjection,
    math3d.Matrix4 parentTransform,
  ) {
    // Combine parent transform with node's transform
    final worldTransform = parentTransform * node.transform;

    // Render the shape if present
    if (node.shape != null) {
      renderer.renderShape(node.shape!, worldTransform, viewProjection);
    }

    // Render children
    for (final child in node.children) {
      _renderNodeBraille(renderer, child, viewProjection, worldTransform);
    }
  }

  /// Recursively renders a scene node with back-face culling.
  void _renderNodeCulled(
    Renderer renderer,
    SceneNode node,
    math3d.Matrix4 viewProjection,
    math3d.Matrix4 parentTransform,
  ) {
    // Combine parent transform with node's transform
    final worldTransform = parentTransform * node.transform;

    // Render the shape if present using culled rendering
    if (node.shape != null) {
      renderer.renderShapeCulled(node.shape!, worldTransform, viewProjection);
    }

    // Render children
    for (final child in node.children) {
      _renderNodeCulled(renderer, child, viewProjection, worldTransform);
    }
  }

  /// Recursively renders a scene node using Braille with back-face culling.
  void _renderNodeBrailleCulled(
    BrailleRenderer renderer,
    SceneNode node,
    math3d.Matrix4 viewProjection,
    math3d.Matrix4 parentTransform,
  ) {
    // Combine parent transform with node's transform
    final worldTransform = parentTransform * node.transform;

    // Render the shape if present using culled rendering
    if (node.shape != null) {
      renderer.renderShapeCulled(node.shape!, worldTransform, viewProjection);
    }

    // Render children
    for (final child in node.children) {
      _renderNodeBrailleCulled(renderer, child, viewProjection, worldTransform);
    }
  }

  /// Recursively renders a scene node using the solid ASCII renderer.
  void _renderNodeSolid(
    SolidRenderer renderer,
    SceneNode node,
    math3d.Matrix4 viewProjection,
    math3d.Matrix4 parentTransform,
  ) {
    // Combine parent transform with node's transform
    final worldTransform = parentTransform * node.transform;

    // Render the shape if present
    if (node.shape != null) {
      renderer.renderShape(
          node.shape!, worldTransform, viewProjection, _shadingStyle);
    }

    // Render children
    for (final child in node.children) {
      _renderNodeSolid(renderer, child, viewProjection, worldTransform);
    }
  }

  /// Recursively renders a scene node using the solid Braille renderer.
  void _renderNodeSolidBraille(
    BrailleSolidRenderer renderer,
    SceneNode node,
    math3d.Matrix4 viewProjection,
    math3d.Matrix4 parentTransform,
  ) {
    // Combine parent transform with node's transform
    final worldTransform = parentTransform * node.transform;

    // Render the shape if present
    if (node.shape != null) {
      renderer.renderShape(
          node.shape!, worldTransform, viewProjection, _shadingStyle);
    }

    // Render children
    for (final child in node.children) {
      _renderNodeSolidBraille(renderer, child, viewProjection, worldTransform);
    }
  }

  /// Renders a particle scene node using ASCII.
  void _renderParticleNode(
    Renderer renderer,
    ParticleSceneNode particleNode,
    math3d.Matrix4 viewProjection,
  ) {
    final particles = particleNode.particleSystem.particles;
    final transform = particleNode.transform;

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

  /// Renders a particle scene node using Braille.
  void _renderParticleNodeBraille(
    BrailleRenderer renderer,
    ParticleSceneNode particleNode,
    math3d.Matrix4 viewProjection,
  ) {
    final particles = particleNode.particleSystem.particles;
    final transform = particleNode.transform;

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

  /// Transforms a point by a matrix.
  math3d.Vector3 _transformPoint(math3d.Vector3 point, math3d.Matrix4 matrix) {
    final m = matrix.values;
    final x = m[0] * point.x + m[4] * point.y + m[8] * point.z + m[12];
    final y = m[1] * point.x + m[5] * point.y + m[9] * point.z + m[13];
    final z = m[2] * point.x + m[6] * point.y + m[10] * point.z + m[14];
    final w = m[3] * point.x + m[7] * point.y + m[11] * point.z + m[15];
    if (w != 0 && w != 1) {
      return math3d.Vector3(x / w, y / w, z / w);
    }
    return math3d.Vector3(x, y, z);
  }
}
