'use client';

import React, { useEffect, useRef, useState } from 'react';
import * as THREE from 'three';
import { GLTFLoader } from 'three/addons/loaders/GLTFLoader.js';

interface Monogram3DViewerProps {
  className?: string;
  autoRotate?: boolean;
  /**
   * Rotation duration in seconds for a complete 360° revolution.
   * Default is 10 seconds (smooth, steady architectural presentation).
   */
  revolutionDuration?: number;
  /**
   * Legacy or alternative speed parameter. If provided, overrides revolutionDuration.
   */
  rotationSpeed?: number;
  fallbackSrc?: string;
  alt?: string;
}

export function Monogram3DViewer({
  className = 'w-full h-full',
  autoRotate = true,
  revolutionDuration = 10,
  rotationSpeed,
  fallbackSrc = '/draughtsman_logo.jpeg',
  alt = 'Architectural Hexagonal Monogram 3D',
}: Monogram3DViewerProps) {
  const containerRef = useRef<HTMLDivElement>(null);
  const canvasRef = useRef<HTMLCanvasElement>(null);
  const [isLoading, setIsLoading] = useState(true);
  const [hasError, setHasError] = useState(false);

  useEffect(() => {
    const container = containerRef.current;
    const canvas = canvasRef.current;
    if (!container || !canvas) return;

    let animationFrameId: number;
    let renderer: THREE.WebGLRenderer | null = null;
    let isDisposed = false;

    // Check if WebGL is supported
    try {
      renderer = new THREE.WebGLRenderer({
        canvas,
        alpha: true,
        antialias: true,
        powerPreference: 'high-performance',
      });
    } catch (err) {
      console.warn('WebGL initialization failed, falling back to static logo:', err);
      setHasError(true);
      setIsLoading(false);
      return;
    }

    const width = container.clientWidth || 128;
    const height = container.clientHeight || 128;
    renderer.setSize(width, height);
    renderer.setPixelRatio(Math.min(window.devicePixelRatio, 2));

    const scene = new THREE.Scene();

    // Field of view tuned to 36° so the monogram occupies ~80% of container height without clipping
    const camera = new THREE.PerspectiveCamera(36, width / height, 0.1, 50);
    camera.position.set(0, 0, 3.9);

    // Architectural Studio Lighting tailored for Matte Graphite Monogram
    const ambientLight = new THREE.AmbientLight(0xffffff, 1.2);
    scene.add(ambientLight);

    // Key light highlighting front-top facets
    const keyLight = new THREE.DirectionalLight(0xffffff, 2.4);
    keyLight.position.set(3, 4, 4);
    scene.add(keyLight);

    // Soft architectural fill light from lower left
    const fillLight = new THREE.DirectionalLight(0x94a3b8, 1.2);
    fillLight.position.set(-3, -1, 3);
    scene.add(fillLight);

    // Subtle blue architectural rim light from behind/above to define graphite bevel edges
    const rimLight = new THREE.DirectionalLight(0x60a5fa, 1.6);
    rimLight.position.set(0, 4, -3);
    scene.add(rimLight);

    // Bottom bounce light
    const bounceLight = new THREE.DirectionalLight(0x38bdf8, 0.4);
    bounceLight.position.set(0, -4, 2);
    scene.add(bounceLight);

    // Group hierarchy:
    // scene -> turntableGroup (rotates around vertical Y-axis) -> modelWrapper (fixed orientation correction) -> gltf.scene
    const turntableGroup = new THREE.Group();
    scene.add(turntableGroup);

    const modelWrapper = new THREE.Group();
    turntableGroup.add(modelWrapper);

    const loader = new GLTFLoader();

    // Check for user reduced motion preference
    const mediaQuery = window.matchMedia('(prefers-reduced-motion: reduce)');
    const prefersReducedMotion = mediaQuery.matches;

    loader.load(
      '/models/architectural_hexagonal_monogram.glb',
      (gltf) => {
        if (isDisposed) return;
        const gltfScene = gltf.scene;

        // Apply material enhancements for matte graphite aesthetic
        gltfScene.traverse((child) => {
          if (child instanceof THREE.Mesh && child.material) {
            const mat = child.material as THREE.MeshStandardMaterial;
            if (mat.isMeshStandardMaterial) {
              mat.roughness = 0.42;
              mat.metalness = 0.35;
              mat.needsUpdate = true;
            }
          }
        });

        // Fixed orientation correction:
        // The raw CAD model lies in the XZ plane with its normal along Y.
        // Rotating +90° (+Math.PI / 2) around X orients the front face upright in the XY plane,
        // exactly matching render_front_orthographic.png:
        // - Pointy hexagon apex at the top
        // - Pointy hexagon apex at the bottom
        // - 'D' loop on the left
        // - 'S' cutouts and opening on the right
        gltfScene.rotation.x = Math.PI / 2;

        modelWrapper.add(gltfScene);

        // Center the geometry precisely on all axes (pivot at geometric center)
        const box = new THREE.Box3().setFromObject(modelWrapper);
        const center = box.getCenter(new THREE.Vector3());
        const size = box.getSize(new THREE.Vector3());

        gltfScene.position.x -= center.x;
        gltfScene.position.y -= center.y;
        gltfScene.position.z -= center.z;

        // Scale normalized so the model height is 2.0 (fills ~80% of 36° FOV at z=3.9)
        const primaryDim = Math.max(size.x, size.y);
        if (primaryDim > 0) {
          const targetScale = 2.0 / primaryDim;
          turntableGroup.scale.set(targetScale, targetScale, targetScale);
        }

        // Initial turntable orientation is at 0 (front-facing reference view)
        turntableGroup.rotation.set(0, 0, 0);
        clock.start();

        setIsLoading(false);
      },
      undefined,
      (error) => {
        console.error('Failed to load 3D GLB model:', error);
        if (!isDisposed) {
          setHasError(true);
          setIsLoading(false);
        }
      }
    );

    // Resize observer
    const resizeObserver = new ResizeObserver((entries) => {
      for (const entry of entries) {
        const { width: newW, height: newH } = entry.contentRect;
        if (newW > 0 && newH > 0 && renderer) {
          camera.aspect = newW / newH;
          camera.updateProjectionMatrix();
          renderer.setSize(newW, newH);
        }
      }
    });
    resizeObserver.observe(container);

    // Frame-rate independent turntable rotation
    const clock = new THREE.Clock(false);
    // Default targets ~10s per revolution (~0.628 rad/s)
    const rotSpeedRadPerSec = (2 * Math.PI) / Math.max(revolutionDuration, 1);

    const animate = () => {
      if (isDisposed) return;

      if (clock.running) {
        const delta = clock.getDelta();
        if (autoRotate && !prefersReducedMotion) {
          turntableGroup.rotation.y += rotSpeedRadPerSec * delta;
        }
      }

      renderer?.render(scene, camera);
      animationFrameId = requestAnimationFrame(animate);
    };

    animate();

    return () => {
      isDisposed = true;
      cancelAnimationFrame(animationFrameId);
      resizeObserver.disconnect();

      turntableGroup.traverse((child) => {
        if (child instanceof THREE.Mesh) {
          child.geometry?.dispose();
          if (Array.isArray(child.material)) {
            child.material.forEach((m) => m.dispose());
          } else if (child.material) {
            child.material.dispose();
          }
        }
      });

      renderer?.dispose();
    };
  }, [autoRotate, revolutionDuration, rotationSpeed]);

  if (hasError) {
    return (
      <img
        src={fallbackSrc}
        alt={alt}
        className={`${className} object-contain rounded-lg`}
      />
    );
  }

  return (
    <div
      ref={containerRef}
      className={`relative flex items-center justify-center pointer-events-none bg-transparent ${className}`}
    >
      {isLoading && (
        <div className="absolute inset-0 flex items-center justify-center">
          <span className="h-4 w-4 rounded-full border-2 border-slate-400 border-t-transparent animate-spin" />
        </div>
      )}
      <canvas ref={canvasRef} className="w-full h-full block pointer-events-none bg-transparent" />
    </div>
  );
}
