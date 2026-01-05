import 'dart:async';

import 'package:nocterm/nocterm.dart';

import '../scene/camera.dart';
import '../scene/scene_node.dart';
import 'scene3d.dart';

/// Callback to build scene nodes based on animation value.
///
/// The [t] parameter ranges from 0.0 to 1.0 representing the animation progress.
typedef SceneBuilder = List<SceneNode> Function(double t);

/// An animated 3D scene component.
///
/// Uses a timer-based animation to continuously update the scene.
/// The [builder] callback receives the current animation progress (0.0 to 1.0)
/// and should return the list of scene nodes to render.
class AnimatedScene3D extends StatefulComponent {
  /// Duration of one complete animation cycle.
  final Duration duration;

  /// The camera used to view the scene.
  final Camera camera;

  /// Builder function that creates scene nodes based on animation value.
  final SceneBuilder builder;

  /// Whether to repeat the animation indefinitely.
  final bool repeat;

  /// The character used for wireframe rendering.
  final String wireframeChar;

  /// Target frames per second for the animation.
  final int fps;

  const AnimatedScene3D({
    super.key,
    required this.duration,
    required this.camera,
    required this.builder,
    this.repeat = true,
    this.wireframeChar = '*',
    this.fps = 30,
  });

  @override
  State<AnimatedScene3D> createState() => _AnimatedScene3DState();
}

class _AnimatedScene3DState extends State<AnimatedScene3D> {
  Timer? _timer;
  double _value = 0.0;
  late DateTime _startTime;
  bool _isDisposed = false;

  @override
  void initState() {
    super.initState();
    _startAnimation();
  }

  void _startAnimation() {
    _startTime = DateTime.now();

    // Calculate frame interval from fps
    final frameInterval =
        Duration(milliseconds: (1000 / component.fps).round());

    _timer = Timer.periodic(frameInterval, (_) {
      if (_isDisposed) return;

      final elapsed = DateTime.now().difference(_startTime);
      final durationMs = component.duration.inMicroseconds.toDouble();
      final elapsedMs = elapsed.inMicroseconds.toDouble();

      if (component.repeat) {
        // Loop the animation
        _value = (elapsedMs % durationMs) / durationMs;
      } else {
        // Clamp to 0-1 range
        _value = (elapsedMs / durationMs).clamp(0.0, 1.0);

        // Stop timer when animation completes
        if (_value >= 1.0) {
          _timer?.cancel();
          _timer = null;
        }
      }

      setState(() {});
    });
  }

  @override
  void didUpdateComponent(AnimatedScene3D oldComponent) {
    super.didUpdateComponent(oldComponent);

    // Restart animation if duration or repeat changed
    if (oldComponent.duration != component.duration ||
        oldComponent.repeat != component.repeat ||
        oldComponent.fps != component.fps) {
      _timer?.cancel();
      _startAnimation();
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    _timer?.cancel();
    _timer = null;
    super.dispose();
  }

  @override
  Component build(BuildContext context) {
    return Scene3D(
      camera: component.camera,
      nodes: component.builder(_value),
      wireframeChar: component.wireframeChar,
    );
  }
}
