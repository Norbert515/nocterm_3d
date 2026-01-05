import 'dart:math' as math;

import '../math/math.dart';

/// A camera for viewing the 3D scene.
class Camera {
  final Vector3 position;
  final Vector3 target;
  final Vector3 up;
  final double fov; // in radians
  final double near;
  final double far;

  const Camera({
    this.position = const Vector3(0, 0, 5),
    this.target = Vector3.zero,
    this.up = Vector3.unitY,
    this.fov = 1.0, // ~57 degrees
    this.near = 0.1,
    this.far = 100.0,
  });

  /// Creates an orbiting camera at the given distance and angles.
  factory Camera.orbit({
    double distance = 5,
    double azimuth = 0, // horizontal angle in radians
    double elevation = 0, // vertical angle in radians
    Vector3 target = Vector3.zero,
    double fov = 1.0,
    double near = 0.1,
    double far = 100.0,
  }) {
    // Calculate position from spherical coordinates
    final cosElevation = math.cos(elevation);
    final x = distance * cosElevation * math.sin(azimuth);
    final y = distance * math.sin(elevation);
    final z = distance * cosElevation * math.cos(azimuth);

    return Camera(
      position: Vector3(x, y, z) + target,
      target: target,
      up: Vector3.unitY,
      fov: fov,
      near: near,
      far: far,
    );
  }

  /// Returns the view matrix for this camera.
  Matrix4 get viewMatrix => Matrix4.lookAt(position, target, up);

  /// Returns the projection matrix for the given aspect ratio.
  Matrix4 projectionMatrix(double aspectRatio) =>
      Matrix4.perspective(fov, aspectRatio, near, far);

  /// Returns combined view-projection matrix.
  Matrix4 viewProjectionMatrix(double aspectRatio) =>
      projectionMatrix(aspectRatio) * viewMatrix;

  /// Creates a copy with modified parameters.
  Camera copyWith({
    Vector3? position,
    Vector3? target,
    Vector3? up,
    double? fov,
    double? near,
    double? far,
  }) {
    return Camera(
      position: position ?? this.position,
      target: target ?? this.target,
      up: up ?? this.up,
      fov: fov ?? this.fov,
      near: near ?? this.near,
      far: far ?? this.far,
    );
  }

  @override
  String toString() =>
      'Camera(position: $position, target: $target, fov: $fov)';
}
