import 'dart:math' as math;

import 'package:nocterm/nocterm.dart';
import 'package:nocterm_3d/nocterm_3d.dart';

void main() async {
  await runApp(const RotatingCubeDemo());
}

class RotatingCubeDemo extends StatelessComponent {
  const RotatingCubeDemo({super.key});

  @override
  Component build(BuildContext context) {
    return AnimatedScene3D(
      duration: const Duration(seconds: 4),
      camera: Camera.orbit(distance: 4, elevation: 0.3),
      builder: (t) {
        final angle = t * 2 * math.pi;
        return [
          SceneNode.rotated(angle * 0.5, angle, 0, shape: Cube()),
        ];
      },
    );
  }
}
