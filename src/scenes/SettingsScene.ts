import Phaser from 'phaser';

export class SettingsScene extends Phaser.Scene {
  constructor() {
    super({ key: 'SettingsScene' });
  }

  create() {
    const { width, height } = this.scale;

    this.add.text(width / 2, height / 3, 'Settings', {
      fontSize: '32px',
      color: '#ffffff',
    }).setOrigin(0.5);

    this.add.text(width / 2, height / 2, '(coming soon)', {
      fontSize: '18px',
      color: '#555555',
    }).setOrigin(0.5);

    const back = this.add
      .text(width / 2, height * 0.75, 'Back', { fontSize: '24px', color: '#aaaaaa' })
      .setOrigin(0.5)
      .setInteractive({ useHandCursor: true });

    back.on('pointerover', () => back.setColor('#ffffff'));
    back.on('pointerout', () => back.setColor('#aaaaaa'));
    back.on('pointerdown', () => this.scene.start('MainMenuScene'));
  }
}
