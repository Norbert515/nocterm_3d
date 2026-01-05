import 'dart:async';

import 'package:nocterm/nocterm.dart' hide Matrix4;
import 'package:nocterm_3d/nocterm_3d.dart';

/// Video demo for promotional material.
///
/// Shows a split-screen with syntax-highlighted code on the left
/// and a 3D animation on the right. Features a typing cursor effect
/// when changing values, demonstrating wireframe rendering.
void main() async {
  await runApp(const VideoDemo());
}

class VideoDemo extends StatefulComponent {
  const VideoDemo({super.key});

  @override
  State<VideoDemo> createState() => _VideoDemoState();
}

/// Typing animation state.
enum TypingState {
  idle, // Cursor blinking, no changes
  deleting, // Removing characters
  typing, // Adding characters
}

/// Configuration for a single demo scene.
class SceneConfig {
  final String shapeName;
  final double distance;
  final double elevation;

  const SceneConfig({
    required this.shapeName,
    this.distance = 4,
    this.elevation = 0.3,
  });

  Shape get shape => shapeName == 'Cube' ? Cube() : Pyramid();
}

class _VideoDemoState extends State<VideoDemo> {
  double _time = 0;
  int _sceneIndex = 0;
  bool _showHotReload = false;
  Timer? _animationTimer;
  Timer? _sceneTimer;
  Timer? _hotReloadTimer;
  Timer? _typingTimer;
  Timer? _cursorBlinkTimer;

  // Typing animation state
  TypingState _typingState = TypingState.idle;
  bool _cursorVisible = true;
  String _currentText = 'Cube';
  String _targetText = 'Cube';

  // Track the actual shape being rendered (changes after typing completes)
  String _renderedShape = 'Cube';
  double _renderedDistance = 4;
  double _renderedElevation = 0.3;

  /// All demo scenes to cycle through - wireframe only.
  final List<SceneConfig> _scenes = [
    // Scene 1: Rotating cube wireframe (default view)
    const SceneConfig(shapeName: 'Cube'),
    // Scene 2: Change shape to Pyramid
    const SceneConfig(shapeName: 'Pyramid'),
    // Scene 3: Zoom in closer
    const SceneConfig(shapeName: 'Pyramid', distance: 3, elevation: 0.5),
    // Scene 4: Back to Cube, zoomed out
    const SceneConfig(shapeName: 'Cube', distance: 5, elevation: 0.2),
    // Scene 5: Different angle
    const SceneConfig(shapeName: 'Cube', distance: 4, elevation: 0.6),
  ];

  @override
  void initState() {
    super.initState();

    // Animation timer - 50ms for smooth animation
    _animationTimer = Timer.periodic(const Duration(milliseconds: 50), (_) {
      setState(() {
        _time += 0.05;
      });
    });

    // Cursor blink timer - 500ms toggle when idle
    _cursorBlinkTimer = Timer.periodic(const Duration(milliseconds: 500), (_) {
      if (_typingState == TypingState.idle) {
        setState(() {
          _cursorVisible = !_cursorVisible;
        });
      }
    });

    // Scene change timer - every 3 seconds
    _sceneTimer = Timer.periodic(const Duration(milliseconds: 3000), (_) {
      _nextScene();
    });
  }

  @override
  void dispose() {
    _animationTimer?.cancel();
    _sceneTimer?.cancel();
    _hotReloadTimer?.cancel();
    _typingTimer?.cancel();
    _cursorBlinkTimer?.cancel();
    super.dispose();
  }

  void _nextScene() {
    final nextIndex = (_sceneIndex + 1) % _scenes.length;
    final nextScene = _scenes[nextIndex];

    // Start typing animation if shape name changes
    if (nextScene.shapeName != _currentText) {
      _targetText = nextScene.shapeName;
      _startDeletingAnimation();
    }

    setState(() {
      _sceneIndex = nextIndex;
    });
  }

  void _startDeletingAnimation() {
    _typingTimer?.cancel();
    setState(() {
      _typingState = TypingState.deleting;
      _cursorVisible = true;
    });

    // Delete at 50ms per character
    _typingTimer = Timer.periodic(const Duration(milliseconds: 50), (_) {
      if (_currentText.isNotEmpty) {
        setState(() {
          _currentText = _currentText.substring(0, _currentText.length - 1);
        });
      } else {
        _typingTimer?.cancel();
        _startTypingAnimation();
      }
    });
  }

  void _startTypingAnimation() {
    var charIndex = 0;
    setState(() {
      _typingState = TypingState.typing;
      _cursorVisible = true;
    });

    // Type at 80ms per character
    _typingTimer = Timer.periodic(const Duration(milliseconds: 80), (_) {
      if (charIndex < _targetText.length) {
        setState(() {
          _currentText = _targetText.substring(0, charIndex + 1);
        });
        charIndex++;
      } else {
        _typingTimer?.cancel();
        _finishTypingAnimation();
      }
    });
  }

  void _finishTypingAnimation() {
    final scene = _scenes[_sceneIndex];
    setState(() {
      _typingState = TypingState.idle;
      // NOW update the rendered values (after typing completes)
      _renderedShape = _currentText;
      _renderedDistance = scene.distance;
      _renderedElevation = scene.elevation;
      _showHotReload = true;
    });

    // Hide "Hot Reloaded" after 1 second
    _hotReloadTimer?.cancel();
    _hotReloadTimer = Timer(const Duration(seconds: 1), () {
      setState(() {
        _showHotReload = false;
      });
    });
  }

  @override
  Component build(BuildContext context) {
    return Column(
      children: [
        // Title bar
        _buildTitleBar(),
        // Main content: code viewer + 3D scene
        Expanded(
          child: Row(
            children: [
              // Left panel: Code viewer (~40%)
              Expanded(
                flex: 2,
                child: _buildCodeViewer(),
              ),
              // Right panel: 3D scene (~60%)
              Expanded(
                flex: 3,
                child: _build3DScene(),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Component _buildTitleBar() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 1, horizontal: 2),
      color: Color.fromRGB(25, 25, 25),
      child: Row(
        children: [
          Text(
            'nocterm_3d',
            style: TextStyle(color: Colors.cyan),
          ),
          const Text(' - '),
          Text(
            'Declarative 3D for Terminal',
            style: TextStyle(color: Colors.grey),
          ),
          const Spacer(),
          if (_showHotReload)
            Text(
              '⚡ Hot Reloaded',
              style: TextStyle(color: Colors.yellow),
            ),
        ],
      ),
    );
  }

  Component _buildCodeViewer() {
    return Container(
      decoration: BoxDecoration(
        color: Color.fromRGB(25, 25, 25),
        border: BoxBorder.all(
          style: BoxBorderStyle.rounded,
          color: Colors.brightBlack,
        ),
      ),
      padding: const EdgeInsets.all(2),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Code snippet with syntax highlighting
          ..._buildCodeLines(),
        ],
      ),
    );
  }

  /// Whether to show the cursor.
  bool _shouldShowCursor() {
    return _typingState != TypingState.idle ||
        (_typingState == TypingState.idle && _cursorVisible);
  }

  List<Component> _buildCodeLines() {
    final lines = <Component>[];

    // Scene3D(
    lines.add(_codeLine([
      _type('Scene3D'),
      _punct('('),
    ]));

    // camera: Camera.orbit(
    lines.add(_codeLine([
      _indent(2),
      _property('camera'),
      _punct(': '),
      _type('Camera'),
      _punct('.'),
      _method('orbit'),
      _punct('('),
    ]));

    // distance: 4,
    lines.add(_codeLine([
      _indent(4),
      _property('distance'),
      _punct(': '),
      _number('4'),
      _punct(','),
    ]));

    // elevation: 0.3,
    lines.add(_codeLine([
      _indent(4),
      _property('elevation'),
      _punct(': '),
      _number('0.3'),
      _punct(','),
    ]));

    // ),
    lines.add(_codeLine([
      _indent(2),
      _punct('),'),
    ]));

    // renderMode: RenderMode.braille,
    lines.add(_codeLine([
      _indent(2),
      _property('renderMode'),
      _punct(': '),
      _type('RenderMode'),
      _punct('.'),
      _enumValue('braille'),
      _punct(','),
    ]));

    // nodes: [
    lines.add(_codeLine([
      _indent(2),
      _property('nodes'),
      _punct(': ['),
    ]));

    // SceneNode.rotated(
    lines.add(_codeLine([
      _indent(4),
      _type('SceneNode'),
      _punct('.'),
      _method('rotated'),
      _punct('('),
    ]));

    // time * 0.5,  // X rotation
    lines.add(_codeLine([
      _indent(6),
      _variable('time'),
      _punct(' * '),
      _number('0.5'),
      _punct(','),
      _comment('  // X'),
    ]));

    // time,  // Y rotation
    lines.add(_codeLine([
      _indent(6),
      _variable('time'),
      _punct(','),
      _comment('  // Y'),
    ]));

    // 0,  // Z rotation
    lines.add(_codeLine([
      _indent(6),
      _number('0'),
      _punct(','),
      _comment('  // Z'),
    ]));

    // shape: Cube(), (with typing cursor effect using underline decoration)
    lines.add(_codeLine([
      _indent(6),
      _property('shape'),
      _punct(': '),
      _typeWithUnderlineCursor(_currentText, _shouldShowCursor()),
      _punct('(),'),
    ]));

    // ),
    lines.add(_codeLine([
      _indent(4),
      _punct('),'),
    ]));

    // ],
    lines.add(_codeLine([
      _indent(2),
      _punct('],'),
    ]));

    // )
    lines.add(_codeLine([
      _punct(')'),
    ]));

    return lines;
  }

  Component _build3DScene() {
    // Use shape based on _renderedShape (changes AFTER typing completes)
    final shape = _renderedShape == 'Pyramid' ? Pyramid() : Cube();

    return Scene3D(
      camera: Camera.orbit(distance: _renderedDistance, elevation: _renderedElevation),
      renderMode: RenderMode.braille,
      nodes: [
        SceneNode.rotated(
          _time * 0.5,
          _time,
          0,
          shape: shape,
        ),
      ],
    );
  }

  // Helper methods for syntax highlighting

  Component _codeLine(List<Component> children) {
    return Row(
      children: children,
    );
  }

  Component _indent(int spaces) {
    return Text(' ' * spaces);
  }

  Component _type(String text) {
    return Text(text, style: TextStyle(color: Colors.cyan));
  }

  /// Renders text with an underline cursor on the last character (or a space if empty).
  /// The underline doesn't change layout - it's a decoration on the existing character.
  Component _typeWithUnderlineCursor(String text, bool showCursor) {
    if (text.isEmpty) {
      // When empty, show cursor as underlined space
      return Text(
        showCursor ? ' ' : '',
        style: TextStyle(
          color: Colors.cyan,
          decoration: showCursor ? TextDecoration.underline : null,
        ),
      );
    }

    if (!showCursor) {
      // No cursor, just show the text
      return Text(text, style: TextStyle(color: Colors.cyan));
    }

    // Show text with last character underlined (cursor position)
    final beforeCursor = text.substring(0, text.length - 1);
    final atCursor = text.substring(text.length - 1);

    return Row(
      children: [
        if (beforeCursor.isNotEmpty)
          Text(beforeCursor, style: TextStyle(color: Colors.cyan)),
        Text(
          atCursor,
          style: TextStyle(
            color: Colors.cyan,
            decoration: TextDecoration.underline,
          ),
        ),
      ],
    );
  }

  Component _method(String text) {
    return Text(text, style: TextStyle(color: Colors.brightCyan));
  }

  Component _property(String text) {
    return Text(text, style: TextStyle(color: Colors.white));
  }

  Component _variable(String text) {
    return Text(text, style: TextStyle(color: Colors.magenta));
  }

  Component _number(String text) {
    return Text(text, style: TextStyle(color: Colors.yellow));
  }

  Component _punct(String text) {
    return Text(text, style: TextStyle(color: Colors.white));
  }

  Component _enumValue(String text) {
    return Text(text, style: TextStyle(color: Colors.brightYellow));
  }

  Component _comment(String text) {
    return Text(text, style: TextStyle(color: Colors.brightBlack));
  }
}
