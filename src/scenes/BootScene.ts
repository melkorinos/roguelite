import Phaser from 'phaser';

export class BootScene extends Phaser.Scene {
  constructor() {
    super({ key: 'BootScene' });
  }

  preload() {
    // load assets here
  }

  create() {
    this.scene.start('MainMenuScene');
  }
}
