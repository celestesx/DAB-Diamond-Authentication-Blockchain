import { Application } from '@splinetool/runtime';

// Spline 3D Scene Loader
class SplineLoader {
  constructor(canvasId, sceneUrl) {
    this.canvasId = canvasId;
    this.sceneUrl = sceneUrl;
    this.app = null;
  }

  async init() {
    try {
      const canvas = document.getElementById(this.canvasId);
      if (!canvas) {
        throw new Error(`Canvas with id "${this.canvasId}" not found`);
      }

      this.app = new Application(canvas);
      await this.app.load(this.sceneUrl);
      console.log('Spline scene loaded successfully');
      return true;
    } catch (error) {
      console.error('Error loading Spline scene:', error);
      return false;
    }
  }

  // Optional: Methods to interact with the scene
  getApp() {
    return this.app;
  }
}

// Auto-initialize when DOM is ready
document.addEventListener('DOMContentLoaded', () => {
  const splineLoader = new SplineLoader(
    'canvas3d',
    'https://prod.spline.design/wEhJcEmjxsOnMxcj/scene.splinecode'
  );
  
  splineLoader.init();
});

export { SplineLoader }; 