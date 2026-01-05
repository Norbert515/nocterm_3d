/// Controls animations in the 3D scene.
class AnimationController {
  final Duration duration;
  final bool loop;

  AnimationController({
    required this.duration,
    this.loop = true,
  });
}
