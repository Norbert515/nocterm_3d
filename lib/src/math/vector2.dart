import 'dart:math' as math;

/// A 2D vector representation for screen coordinates.
class Vector2 {
  final double x;
  final double y;

  const Vector2(this.x, this.y);

  static const zero = Vector2(0, 0);
  static const one = Vector2(1, 1);
  static const unitX = Vector2(1, 0);
  static const unitY = Vector2(0, 1);

  /// Adds two vectors.
  Vector2 operator +(Vector2 other) {
    return Vector2(x + other.x, y + other.y);
  }

  /// Subtracts two vectors.
  Vector2 operator -(Vector2 other) {
    return Vector2(x - other.x, y - other.y);
  }

  /// Multiplies by a scalar.
  Vector2 operator *(double scalar) {
    return Vector2(x * scalar, y * scalar);
  }

  /// Divides by a scalar.
  Vector2 operator /(double scalar) {
    return Vector2(x / scalar, y / scalar);
  }

  /// Negates the vector.
  Vector2 operator -() {
    return Vector2(-x, -y);
  }

  /// Computes the dot product with another vector.
  double dot(Vector2 other) {
    return x * other.x + y * other.y;
  }

  /// The squared magnitude of this vector (faster than [length]).
  double get lengthSquared => x * x + y * y;

  /// The magnitude of this vector.
  double get length => math.sqrt(lengthSquared);

  /// Returns a normalized (unit length) version of this vector.
  Vector2 get normalized {
    final len = length;
    if (len == 0) return Vector2.zero;
    return this / len;
  }

  /// Linearly interpolates between this vector and [other] by [t].
  Vector2 lerp(Vector2 other, double t) {
    return Vector2(
      x + (other.x - x) * t,
      y + (other.y - y) * t,
    );
  }

  @override
  String toString() => 'Vector2($x, $y)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Vector2 && other.x == x && other.y == y;
  }

  @override
  int get hashCode => Object.hash(x, y);
}
