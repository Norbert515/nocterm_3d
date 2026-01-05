import 'dart:async';

import 'package:nocterm/nocterm.dart' hide Matrix4;
import 'package:nocterm_3d/nocterm_3d.dart';

void main() async {
  await runApp(const ParticleCubeDemo());
}

class ParticleCubeDemo extends StatefulComponent {
  const ParticleCubeDemo({super.key});

  @override
  State<ParticleCubeDemo> createState() => _ParticleCubeDemoState();
}

class _ParticleCubeDemoState extends State<ParticleCubeDemo> {
  final _particleSystem = ParticleSystem(
    emitter: CubeEmitter(
      size: 0.5,
      speed: 0.3,
      chars: ['·', '∙', '•', '°', '✦'],
    ),
    maxParticles: 150,
    emissionRate: 30,
    particleLifetime: 3.0,
    brownianStrength: 0.2,
  );

  double _time = 0;
  Timer? _timer;
  RenderMode _renderMode = RenderMode.braille;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(milliseconds: 33), (_) {
      setState(() {
        _time += 0.033;
        _particleSystem.update(0.033);
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  bool _handleKeyEvent(LogicalKey key) {
    if (key == LogicalKey.space) {
      setState(() {
        _renderMode = _renderMode == RenderMode.braille
            ? RenderMode.ascii
            : RenderMode.braille;
      });
      return true;
    }
    return false;
  }

  @override
  Component build(BuildContext context) {
    final angle = _time * 0.5;
    return KeyboardListener(
      autofocus: true,
      onKeyEvent: _handleKeyEvent,
      child: Column(
        children: [
          Text(
            'Particles: ${_particleSystem.particles.length} | '
            'Mode: ${_renderMode == RenderMode.braille ? "Braille" : "ASCII"} | '
            'Press Space to toggle',
          ),
          Expanded(
            child: Scene3D(
              camera: Camera.orbit(distance: 5, elevation: 0.3),
              renderMode: _renderMode,
              nodes: [
                SceneNode.rotated(angle * 0.3, angle, 0, shape: Cube()),
              ],
              particleNodes: [
                ParticleSceneNode(particleSystem: _particleSystem),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
