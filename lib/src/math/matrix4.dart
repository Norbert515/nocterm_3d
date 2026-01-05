import 'dart:math' as math;

import 'vector3.dart';

/// A 4x4 transformation matrix using column-major order (like OpenGL).
///
/// The matrix layout is:
/// ```
/// | m0  m4  m8   m12 |
/// | m1  m5  m9   m13 |
/// | m2  m6  m10  m14 |
/// | m3  m7  m11  m15 |
/// ```
///
/// Column 0: m0, m1, m2, m3
/// Column 1: m4, m5, m6, m7
/// Column 2: m8, m9, m10, m11
/// Column 3: m12, m13, m14, m15
class Matrix4 {
  final List<double> values;

  /// Creates a Matrix4 from a list of 16 values in column-major order.
  ///
  /// The list must contain exactly 16 elements.
  const Matrix4(this.values);

  /// Creates an identity matrix.
  static Matrix4 identity() {
    return const Matrix4([
      1, 0, 0, 0,
      0, 1, 0, 0,
      0, 0, 1, 0,
      0, 0, 0, 1,
    ]);
  }

  /// Creates a translation matrix.
  static Matrix4 translation(double x, double y, double z) {
    return Matrix4([
      1, 0, 0, 0,
      0, 1, 0, 0,
      0, 0, 1, 0,
      x, y, z, 1,
    ]);
  }

  /// Creates a scale matrix.
  static Matrix4 scale(double x, double y, double z) {
    return Matrix4([
      x, 0, 0, 0,
      0, y, 0, 0,
      0, 0, z, 0,
      0, 0, 0, 1,
    ]);
  }

  /// Creates a rotation matrix around the X axis.
  static Matrix4 rotationX(double radians) {
    final c = math.cos(radians);
    final s = math.sin(radians);
    return Matrix4([
      1, 0, 0, 0,
      0, c, s, 0,
      0, -s, c, 0,
      0, 0, 0, 1,
    ]);
  }

  /// Creates a rotation matrix around the Y axis.
  static Matrix4 rotationY(double radians) {
    final c = math.cos(radians);
    final s = math.sin(radians);
    return Matrix4([
      c, 0, -s, 0,
      0, 1, 0, 0,
      s, 0, c, 0,
      0, 0, 0, 1,
    ]);
  }

  /// Creates a rotation matrix around the Z axis.
  static Matrix4 rotationZ(double radians) {
    final c = math.cos(radians);
    final s = math.sin(radians);
    return Matrix4([
      c, s, 0, 0,
      -s, c, 0, 0,
      0, 0, 1, 0,
      0, 0, 0, 1,
    ]);
  }

  /// Creates a perspective projection matrix.
  ///
  /// [fov] is the vertical field of view in radians.
  /// [aspect] is the aspect ratio (width / height).
  /// [near] is the near clipping plane distance.
  /// [far] is the far clipping plane distance.
  static Matrix4 perspective(double fov, double aspect, double near, double far) {
    final tanHalfFov = math.tan(fov / 2);
    final f = 1.0 / tanHalfFov;
    final rangeInv = 1.0 / (near - far);

    return Matrix4([
      f / aspect, 0, 0, 0,
      0, f, 0, 0,
      0, 0, (far + near) * rangeInv, -1,
      0, 0, 2 * far * near * rangeInv, 0,
    ]);
  }

  /// Creates a view matrix looking from [eye] towards [target] with [up] direction.
  static Matrix4 lookAt(Vector3 eye, Vector3 target, Vector3 up) {
    final zAxis = (eye - target).normalized;
    final xAxis = up.cross(zAxis).normalized;
    final yAxis = zAxis.cross(xAxis);

    return Matrix4([
      xAxis.x, yAxis.x, zAxis.x, 0,
      xAxis.y, yAxis.y, zAxis.y, 0,
      xAxis.z, yAxis.z, zAxis.z, 0,
      -xAxis.dot(eye), -yAxis.dot(eye), -zAxis.dot(eye), 1,
    ]);
  }

  /// Multiplies this matrix by [other].
  Matrix4 operator *(Matrix4 other) {
    final a = values;
    final b = other.values;
    final result = List<double>.filled(16, 0);

    for (var col = 0; col < 4; col++) {
      for (var row = 0; row < 4; row++) {
        var sum = 0.0;
        for (var k = 0; k < 4; k++) {
          // a[row + k*4] is the element at (row, k) in this matrix
          // b[k + col*4] is the element at (k, col) in other matrix
          sum += a[row + k * 4] * b[k + col * 4];
        }
        result[row + col * 4] = sum;
      }
    }

    return Matrix4(result);
  }

  /// Transforms a point (with w=1, so translation is applied).
  Vector3 transform(Vector3 v) {
    final m = values;
    final x = m[0] * v.x + m[4] * v.y + m[8] * v.z + m[12];
    final y = m[1] * v.x + m[5] * v.y + m[9] * v.z + m[13];
    final z = m[2] * v.x + m[6] * v.y + m[10] * v.z + m[14];
    final w = m[3] * v.x + m[7] * v.y + m[11] * v.z + m[15];

    if (w != 1.0 && w != 0.0) {
      return Vector3(x / w, y / w, z / w);
    }
    return Vector3(x, y, z);
  }

  /// Transforms a direction vector (with w=0, so translation is not applied).
  Vector3 transformDirection(Vector3 v) {
    final m = values;
    return Vector3(
      m[0] * v.x + m[4] * v.y + m[8] * v.z,
      m[1] * v.x + m[5] * v.y + m[9] * v.z,
      m[2] * v.x + m[6] * v.y + m[10] * v.z,
    );
  }

  @override
  String toString() {
    return 'Matrix4(\n'
        '  ${values[0]}, ${values[4]}, ${values[8]}, ${values[12]}\n'
        '  ${values[1]}, ${values[5]}, ${values[9]}, ${values[13]}\n'
        '  ${values[2]}, ${values[6]}, ${values[10]}, ${values[14]}\n'
        '  ${values[3]}, ${values[7]}, ${values[11]}, ${values[15]}\n'
        ')';
  }
}
