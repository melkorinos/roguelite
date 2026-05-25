import Phaser from 'phaser';
import { createInitialGameState, GameState } from '../data/types';
import { movePlayer, InputState } from '../systems/MovementSystem';

export class GameScene extends Phaser.Scene {
  private state!: GameState;
  private playerSprite!: Phaser.GameObjects.Rectangle;
  private itemSprites: Map<string, Phaser.GameObjects.Rectangle> = new Map();
  private cursors!: Phaser.Types.Input.Keyboard.CursorKeys;

  constructor() {
    super({ key: 'GameScene' });
  }

  create() {
    this.state = createInitialGameState();

    // Room boundary
    this.add.rectangle(400, 300, 780, 560).setStrokeStyle(2, 0x333355);

    // Player placeholder
    this.playerSprite = this.add.rectangle(
      this.state.player.position.x,
      this.state.player.position.y,
      28, 28, 0x00ff88
    );

    // Spawn one item
    this.state.items.push({
      id: 'item_0',
      type: 'scrap',
      position: { x: 200, y: 200 },
      collected: false,
    });

    for (const item of this.state.items) {
      const sprite = this.add.rectangle(item.position.x, item.position.y, 16, 16, 0xffaa00);
      this.itemSprites.set(item.id, sprite);
    }

    this.cursors = this.input.keyboard!.createCursorKeys();
  }

  update(_time: number, delta: number) {
    const input: InputState = {
      left: this.cursors.left.isDown,
      right: this.cursors.right.isDown,
      up: this.cursors.up.isDown,
      down: this.cursors.down.isDown,
    };

    this.state = movePlayer(this.state, input, delta);

    this.playerSprite.setPosition(
      this.state.player.position.x,
      this.state.player.position.y
    );

    this.registry.set('playerHealth', this.state.player.health);
  }
}
