import 'dart:math' as math;

import '../math/math.dart';

/// A single particle with position, velocity, and lifetime.
class Particle {
  Vector3 position;
  Vector3 velocity;
  double life; // 0.0 to 1.0, decreases over time
  final String char; // character to render

  Particle({
    required this.position,
    required this.velocity,
    this.life = 1.0,
    this.char = '·',
  });

  /// Updates the particle position and applies brownian motion.
  /// Returns false if the particle is dead.
  bool update(double dt, math.Random random, {double brownianStrength = 0.1}) {
    // Add brownian motion (random displacement to velocity)
    final brownianX = (random.nextDouble() - 0.5) * 2 * brownianStrength;
    final brownianY = (random.nextDouble() - 0.5) * 2 * brownianStrength;
    final brownianZ = (random.nextDouble() - 0.5) * 2 * brownianStrength;

    velocity = Vector3(
      velocity.x + brownianX * dt,
      velocity.y + brownianY * dt,
      velocity.z + brownianZ * dt,
    );

    // Update position based on velocity
    position = position + velocity * dt;

    // Decrease life
    life -= dt;

    return life > 0;
  }
}
