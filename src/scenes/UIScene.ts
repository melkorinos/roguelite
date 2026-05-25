import Phaser from 'phaser';

export class UIScene extends Phaser.Scene {
  private healthText!: Phaser.GameObjects.Text;

  constructor() {
    super({ key: 'UIScene' });
  }

  create() {
    this.healthText = this.add.text(12, 12, 'HP: 100', {
      fontSize: '16px',
      color: '#00ff88',
    });

    this.registry.events.on('changedata-playerHealth', (_parent: unknown, value: number) => {
      this.healthText.setText(`HP: ${value}`);
    });
  }
}
