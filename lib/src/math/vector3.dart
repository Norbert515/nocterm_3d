import 'dart:math' as math;

/// A 3D vector representation.
class Vector3 {
  final double x;
  final double y;
  final double z;

  const Vector3(this.x, this.y, this.z);

  static const zero = Vector3(0, 0, 0);
  static const one = Vector3(1, 1, 1);
  static const unitX = Vector3(1, 0, 0);
  static const unitY = Vector3(0, 1, 0);
  static const unitZ = Vector3(0, 0, 1);

  /// Adds two vectors.
  Vector3 operator +(Vector3 other) {
    return Vector3(x + other.x, y + other.y, z + other.z);
  }

  /// Subtracts two vectors.
  Vector3 operator -(Vector3 other) {
    return Vector3(x - other.x, y - other.y, z - other.z);
  }

  /// Multiplies by a scalar.
  Vector3 operator *(double scalar) {
    return Vector3(x * scalar, y * scalar, z * scalar);
  }

  /// Divides by a scalar.
  Vector3 operator /(double scalar) {
    return Vector3(x / scalar, y / scalar, z / scalar);
  }

  /// Negates the vector.
  Vector3 operator -() {
    return Vector3(-x, -y, -z);
  }

  /// Computes the dot product with another vector.
  double dot(Vector3 other) {
    return x * other.x + y * other.y + z * other.z;
  }

  /// Computes the cross product with another vector.
  Vector3 cross(Vector3 other) {
    return Vector3(
      y * other.z - z * other.y,
      z * other.x - x * other.z,
      x * other.y - y * other.x,
    );
  }

  /// The squared magnitude of this vector (faster than [length]).
  double get lengthSquared => x * x + y * y + z * z;

  /// The magnitude of this vector.
  double get length => math.sqrt(lengthSquared);

  /// Returns a normalized (unit length) version of this vector.
  Vector3 get normalized {
    final len = length;
    if (len == 0) return Vector3.zero;
    return this / len;
  }

  /// Linearly interpolates between this vector and [other] by [t].
  Vector3 lerp(Vector3 other, double t) {
    return Vector3(
      x + (other.x - x) * t,
      y + (other.y - y) * t,
      z + (other.z - z) * t,
    );
  }

  @override
  String toString() => 'Vector3($x, $y, $z)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Vector3 && other.x == x && other.y == y && other.z == z;
  }

  @override
  int get hashCode => Object.hash(x, y, z);
}
