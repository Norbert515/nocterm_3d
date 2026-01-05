import 'dart:async';
import 'dart:math' as math;

import 'package:nocterm/nocterm.dart' hide Matrix4;
import 'package:nocterm_3d/nocterm_3d.dart';

/// Example demonstrating solid/shaded rendering with ASCII density-based lighting.
///
/// Press 'm' to cycle through render modes, 's' to cycle shading styles, 'q' to quit.
void main() async {
  await runApp(const ShadedCubeDemo());
}

class ShadedCubeDemo extends StatefulComponent {
  const ShadedCubeDemo({super.key});

  @override
  State<ShadedCubeDemo> createState() => _ShadedCubeDemoState();
}

class _ShadedCubeDemoState extends State<ShadedCubeDemo> {
  double _time = 0;
  RenderMode _renderMode = RenderMode.solidAscii;
  ShadingStyle _shadingStyle = ShadingStyle.lit;
  Timer? _timer;

  final List<RenderMode> _modes = [
    RenderMode.ascii,
    RenderMode.braille,
    RenderMode.asciiCulled,
    RenderMode.brailleCulled,
    RenderMode.solidAscii,
    RenderMode.solidBraille,
  ];

  final List<ShadingStyle> _styles = [
    ShadingStyle.wireframe,
    ShadingStyle.solid,
    ShadingStyle.depth,
    ShadingStyle.lit,
  ];

  int _modeIndex = 4; // Start with solidAscii
  int _styleIndex = 3; // Start with lit

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(milliseconds: 50), (_) {
      setState(() {
        _time += 0.05;
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _cycleMode() {
    setState(() {
      _modeIndex = (_modeIndex + 1) % _modes.length;
      _renderMode = _modes[_modeIndex];
    });
  }

  void _cycleStyle() {
    setState(() {
      _styleIndex = (_styleIndex + 1) % _styles.length;
      _shadingStyle = _styles[_styleIndex];
    });
  }

  bool _handleKeyEvent(LogicalKey key) {
    if (key == LogicalKey.keyM) {
      _cycleMode();
      return true;
    } else if (key == LogicalKey.keyS) {
      _cycleStyle();
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
            'Mode: ${_renderMode.name} | Style: ${_shadingStyle.name} | '
            '[M] cycle mode, [S] cycle style, [Q] quit',
          ),
          Expanded(
            child: Scene3D(
              camera: Camera.orbit(distance: 4, elevation: 0.3),
              renderMode: _renderMode,
              shadingStyle: _shadingStyle,
              lightDirection: Vector3(
                math.sin(_time * 0.5),
                0.8,
                math.cos(_time * 0.5),
              ),
              nodes: [
                SceneNode.rotated(
                  _time * 0.5,
                  _time,
                  0,
                  shape: Cube(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
