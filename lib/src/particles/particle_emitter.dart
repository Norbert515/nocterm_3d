import 'dart:math' as math;

import '../math/math.dart';
import 'particle.dart';

/// Defines how particles are emitted.
abstract class ParticleEmitter {
  /// Spawns a new particle.
  Particle spawn(math.Random random);
}

/// Emits particles from a point.
class PointEmitter extends ParticleEmitter {
  final Vector3 origin;
  final double speed;
  final List<String> chars;

  PointEmitter({
    this.origin = Vector3.zero,
    this.speed = 0.5,
    this.chars = const ['·'],
  });

  @override
  Particle spawn(math.Random random) {
    // Random direction using spherical coordinates
    final theta = random.nextDouble() * 2 * math.pi;
    final phi = math.acos(2 * random.nextDouble() - 1);

    final direction = Vector3(
      math.sin(phi) * math.cos(theta),
      math.sin(phi) * math.sin(theta),
      math.cos(phi),
    );

    final char = chars[random.nextInt(chars.length)];

    return Particle(
      position: origin,
      velocity: direction * speed,
      char: char,
    );
  }
}

/// Emits particles from the surface of a cube.
class CubeEmitter extends ParticleEmitter {
  final double size;
  final double speed;
  final List<String> chars;

  CubeEmitter({
    this.size = 1.0,
    this.speed = 0.5,
    this.chars = const ['·', '∙', '•', '°'],
  });

  @override
  Particle spawn(math.Random random) {
    final halfSize = size / 2;

    // Pick a random face (0-5)
    final face = random.nextInt(6);

    double x, y, z;
    double nx, ny, nz; // Normal direction for velocity

    switch (face) {
      case 0: // +X face
        x = halfSize;
        y = (random.nextDouble() - 0.5) * size;
        z = (random.nextDouble() - 0.5) * size;
        nx = 1;
        ny = 0;
        nz = 0;
        break;
      case 1: // -X face
        x = -halfSize;
        y = (random.nextDouble() - 0.5) * size;
        z = (random.nextDouble() - 0.5) * size;
        nx = -1;
        ny = 0;
        nz = 0;
        break;
      case 2: // +Y face
        x = (random.nextDouble() - 0.5) * size;
        y = halfSize;
        z = (random.nextDouble() - 0.5) * size;
        nx = 0;
        ny = 1;
        nz = 0;
        break;
      case 3: // -Y face
        x = (random.nextDouble() - 0.5) * size;
        y = -halfSize;
        z = (random.nextDouble() - 0.5) * size;
        nx = 0;
        ny = -1;
        nz = 0;
        break;
      case 4: // +Z face
        x = (random.nextDouble() - 0.5) * size;
        y = (random.nextDouble() - 0.5) * size;
        z = halfSize;
        nx = 0;
        ny = 0;
        nz = 1;
        break;
      default: // -Z face
        x = (random.nextDouble() - 0.5) * size;
        y = (random.nextDouble() - 0.5) * size;
        z = -halfSize;
        nx = 0;
        ny = 0;
        nz = -1;
    }

    final char = chars[random.nextInt(chars.length)];

    return Particle(
      position: Vector3(x, y, z),
      velocity: Vector3(nx * speed, ny * speed, nz * speed),
      char: char,
    );
  }
}

/// Emits particles from the surface of a sphere.
class SphereEmitter extends ParticleEmitter {
  final double radius;
  final double speed;
  final List<String> chars;

  SphereEmitter({
    this.radius = 0.5,
    this.speed = 0.5,
    this.chars = const ['✦', '✧', '·', '°'],
  });

  @override
  Particle spawn(math.Random random) {
    // Random point on sphere surface using spherical coordinates
    final theta = random.nextDouble() * 2 * math.pi;
    final phi = math.acos(2 * random.nextDouble() - 1);

    final direction = Vector3(
      math.sin(phi) * math.cos(theta),
      math.sin(phi) * math.sin(theta),
      math.cos(phi),
    );

    final position = direction * radius;
    final velocity = direction * speed;

    final char = chars[random.nextInt(chars.length)];

    return Particle(
      position: position,
      velocity: velocity,
      char: char,
    );
  }
}
