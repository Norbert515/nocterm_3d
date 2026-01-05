import 'dart:async';
import 'dart:math' as math;

import 'package:nocterm/nocterm.dart' hide Matrix4;
import 'package:nocterm_3d/nocterm_3d.dart';

/// Example demonstrating the difference between ASCII and Braille rendering.
///
/// Press 'b' to toggle Braille mode, 'a' for ASCII mode, or Space to toggle.
void main() async {
  await runApp(const RenderComparisonDemo());
}

class RenderComparisonDemo extends StatefulComponent {
  const RenderComparisonDemo({super.key});

  @override
  State<RenderComparisonDemo> createState() => _RenderComparisonDemoState();
}

class _RenderComparisonDemoState extends State<RenderComparisonDemo> {
  RenderMode _renderMode = RenderMode.braille;
  double _angle = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    // Animate the rotation
    _timer = Timer.periodic(const Duration(milliseconds: 16), (_) {
      setState(() {
        _angle += 0.02;
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _toggleMode() {
    setState(() {
      _renderMode = _renderMode == RenderMode.braille
          ? RenderMode.ascii
          : RenderMode.braille;
    });
  }

  bool _handleKeyEvent(LogicalKey key) {
    if (key == LogicalKey.keyB) {
      setState(() => _renderMode = RenderMode.braille);
      return true;
    } else if (key == LogicalKey.keyA) {
      setState(() => _renderMode = RenderMode.ascii);
      return true;
    } else if (key == LogicalKey.space) {
      _toggleMode();
      return true;
    } else if (key == LogicalKey.keyQ) {
      _timer?.cancel();
      return true;
    }
    return false;
  }

  @override
  Component build(BuildContext context) {
    return KeyboardListener(
      autofocus: true,
      onKeyEvent: _handleKeyEvent,
      child: Column(
        children: [
          Text(
            'Render Mode: ${_renderMode == RenderMode.braille ? "Braille (high-res)" : "ASCII"} | '
            'Press Space to toggle, B for Braille, A for ASCII, Q to quit',
          ),
          Expanded(
            child: Scene3D(
              camera: Camera.orbit(distance: 4, elevation: 0.3),
              renderMode: _renderMode,
              wireframeChar: '*',
              nodes: [
                // Main rotating cube
                SceneNode.rotated(
                  _angle * 0.5,
                  _angle,
                  0,
                  shape: Cube(),
                ),
                // Smaller cube orbiting
                SceneNode.translated(
                  math.cos(_angle * 2) * 2,
                  math.sin(_angle * 2) * 0.5,
                  math.sin(_angle * 2) * 2,
                  children: [
                    SceneNode.scaled(0.3, 0.3, 0.3, shape: Cube()),
                  ],
                ),
                // Pyramid
                SceneNode.translated(
                  -2,
                  0,
                  0,
                  children: [
                    SceneNode.rotated(0, _angle * 1.5, 0, shape: Pyramid()),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
