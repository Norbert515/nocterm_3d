import '../math/math.dart';
import '../particles/particles.dart';

/// A scene node that renders a particle system.
class ParticleSceneNode {
  final ParticleSystem particleSystem;
  final Matrix4 transform;

  ParticleSceneNode({
    required this.particleSystem,
    Matrix4? transform,
  }) : transform = transform ?? Matrix4.identity();
}
