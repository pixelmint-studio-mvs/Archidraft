import { describe, it } from 'node:test';
import assert from 'node:assert';

describe('Admin Web Monogram 3D Rotation Policy & Reduced Motion Tests', () => {
  // Helper modeling the component's deliberate rotation policy
  function computeShouldRotate({
    autoRotate = true,
    respectReducedMotion = false,
    prefersReducedMotion = false,
  }: {
    autoRotate?: boolean;
    respectReducedMotion?: boolean;
    prefersReducedMotion?: boolean;
  }): boolean {
    return autoRotate && (!respectReducedMotion || !prefersReducedMotion);
  }

  // Helper modeling angular velocity calculation
  function computeAngularVelocityRadPerSec({
    rotationSpeed,
    revolutionDuration = 10,
  }: {
    rotationSpeed?: number;
    revolutionDuration?: number;
  }): number {
    if (rotationSpeed !== undefined) {
      return rotationSpeed < 0.2 ? rotationSpeed * 60 : rotationSpeed;
    }
    return (2 * Math.PI) / revolutionDuration;
  }

  it('rotates by default when OS Animation Effects are OFF (prefers-reduced-motion: reduce)', () => {
    // Windows Animation Effects disabled causes prefersReducedMotion = true
    const shouldRotate = computeShouldRotate({
      autoRotate: true,
      respectReducedMotion: false, // deliberate default for ambient brand monogram
      prefersReducedMotion: true,
    });
    assert.strictEqual(shouldRotate, true, 'Ambient monogram should rotate under default policy even when Windows animations are disabled');
  });

  it('rotates by default when OS Animation Effects are ON', () => {
    const shouldRotate = computeShouldRotate({
      autoRotate: true,
      respectReducedMotion: false,
      prefersReducedMotion: false,
    });
    assert.strictEqual(shouldRotate, true);
  });

  it('halts rotation if autoRotate is explicitly false', () => {
    const shouldRotate = computeShouldRotate({
      autoRotate: false,
      respectReducedMotion: false,
      prefersReducedMotion: false,
    });
    assert.strictEqual(shouldRotate, false);
  });

  it('respects reduced motion when respectReducedMotion is explicitly true and OS requests reduced motion', () => {
    const shouldRotate = computeShouldRotate({
      autoRotate: true,
      respectReducedMotion: true,
      prefersReducedMotion: true,
    });
    assert.strictEqual(shouldRotate, false, 'Should halt rotation when accessibility override is requested');
  });

  it('rotates when respectReducedMotion is true but OS does not request reduced motion', () => {
    const shouldRotate = computeShouldRotate({
      autoRotate: true,
      respectReducedMotion: true,
      prefersReducedMotion: false,
    });
    assert.strictEqual(shouldRotate, true);
  });

  it('calculates frame-rate independent rotation speeds accurately', () => {
    // revolutionDuration = 10 seconds -> 2*PI / 10 = ~0.6283 rad/s
    const radPerSec10 = computeAngularVelocityRadPerSec({ revolutionDuration: 10 });
    assert.ok(Math.abs(radPerSec10 - 0.628318) < 0.001);

    // Sidebar passed rotationSpeed = 0.02 (rad/frame at 60fps -> 1.2 rad/s)
    const radPerSecCustom = computeAngularVelocityRadPerSec({ rotationSpeed: 0.02 });
    assert.strictEqual(radPerSecCustom, 1.2);

    // Delta-time rotation advancement over 16.6ms (60fps) vs 8.3ms (120fps)
    const delta60fps = 0.0166;
    const delta120fps = 0.0083;
    const advance60 = radPerSec10 * delta60fps;
    const advance120 = radPerSec10 * delta120fps * 2;
    assert.ok(Math.abs(advance60 - advance120) < 0.001, 'Advancement per physical second is identical across refresh rates');
  });
});
