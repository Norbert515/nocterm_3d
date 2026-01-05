import 'dart:async';

import 'package:nocterm/nocterm.dart' hide Matrix4;
import 'package:nocterm_3d/nocterm_3d.dart';

void main() async {
  await runApp(const Text3DDemo());
}

class Text3DDemo extends StatefulComponent {
  const Text3DDemo({super.key});

  @override
  State<Text3DDemo> createState() => _Text3DDemoState();
}

class _Text3DDemoState extends State<Text3DDemo> {
  double _rotationX = 0;
  double _rotationY = 0;
  double _mouseX = 0.5; // Normalized 0-1
  double _mouseY = 0.5; // Normalized 0-1
  Timer? _timer;

  // Approximate terminal dimensions for normalization
  int _terminalWidth = 80;
  int _terminalHeight = 24;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(milliseconds: 16), (_) {
      setState(() {
        // Smoothly interpolate rotation towards mouse position
        final targetRotationY = (_mouseX - 0.5) * 0.6; // Max ~35 degrees
        final targetRotationX = (_mouseY - 0.5) * -0.4; // Max ~23 degrees

        // Smooth easing
        _rotationY += (targetRotationY - _rotationY) * 0.1;
        _rotationX += (targetRotationX - _rotationX) * 0.1;
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Component build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Update terminal dimensions for accurate mouse normalization
        _terminalWidth = constraints.maxWidth.toInt();
        _terminalHeight = constraints.maxHeight.toInt();

        return MouseRegion(
          onHover: (event) {
            setState(() {
              // Normalize mouse position to 0-1 range
              _mouseX = event.x / _terminalWidth;
              _mouseY = event.y / _terminalHeight;
              _mouseX = _mouseX.clamp(0.0, 1.0);
              _mouseY = _mouseY.clamp(0.0, 1.0);
            });
          },
          child: Scene3D(
            camera: Camera(
              position: Vector3(0, 0, 8),
              target: Vector3.zero,
            ),
            renderMode: RenderMode.braille,
            nodes: [
              SceneNode.rotated(
                _rotationX,
                _rotationY,
                0,
                shape: Text3D('NOCTERM 3D'),
              ),
            ],
          ),
        );
      },
    );
  }
}
