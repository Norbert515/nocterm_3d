import 'dart:math' as math;

import 'particle.dart';
import 'particle_emitter.dart';

/// Manages a collection of particles.
class ParticleSystem {
  final ParticleEmitter emitter;
  final int maxParticles;
  final double emissionRate; // particles per second
  final double particleLifetime; // seconds
  final double brownianStrength;

  final List<Particle> _particles = [];
  final math.Random _random;
  double _emissionAccumulator = 0;

  ParticleSystem({
    required this.emitter,
    this.maxParticles = 100,
    this.emissionRate = 20,
    this.particleLifetime = 2.0,
    this.brownianStrength = 0.3,
    int? seed,
  }) : _random = math.Random(seed);

  List<Particle> get particles => _particles;

  /// Updates the particle system.
  void update(double dt) {
    // Emit new particles based on emission rate
    _emissionAccumulator += emissionRate * dt;

    while (_emissionAccumulator >= 1 && _particles.length < maxParticles) {
      final particle = emitter.spawn(_random);
      // Normalize life to decay from 1.0 to 0.0 over particleLifetime
      particle.life = particleLifetime;
      _particles.add(particle);
      _emissionAccumulator -= 1;
    }

    // Cap accumulator to prevent burst after pause
    if (_emissionAccumulator > emissionRate) {
      _emissionAccumulator = emissionRate;
    }

    // Update existing particles and remove dead ones
    _particles.removeWhere((particle) {
      // Update returns false if particle is dead
      return !particle.update(
        dt,
        _random,
        brownianStrength: brownianStrength,
      );
    });
  }

  /// Resets the particle system.
  void reset() {
    _particles.clear();
    _emissionAccumulator = 0;
  }
}
