import Phaser from 'phaser';

export class MainMenuScene extends Phaser.Scene {
  constructor() {
    super({ key: 'MainMenuScene' });
  }

  create() {
    const { width, height } = this.scale;

    this.add.text(width / 2, height / 3, 'ROGUELITE', {
      fontSize: '48px',
      color: '#ffffff',
    }).setOrigin(0.5);

    this.createButton(width / 2, height / 2, 'Start', () => {
      this.scene.start('GameScene');
      this.scene.launch('UIScene');
    });

    this.createButton(width / 2, height / 2 + 60, 'Settings', () => {
      this.scene.start('SettingsScene');
    });

    this.createButton(width / 2, height / 2 + 120, 'Quit', () => {
      // no-op in browser; handle in desktop wrapper if needed
    });
  }

  private createButton(x: number, y: number, label: string, onClick: () => void) {
    const text = this.add
      .text(x, y, label, { fontSize: '24px', color: '#aaaaaa' })
      .setOrigin(0.5)
      .setInteractive({ useHandCursor: true });

    text.on('pointerover', () => text.setColor('#ffffff'));
    text.on('pointerout', () => text.setColor('#aaaaaa'));
    text.on('pointerdown', onClick);
  }
}
