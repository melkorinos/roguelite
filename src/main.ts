import Phaser from 'phaser';
import { gameConfig } from './config/GameConfig';
import { BootScene } from './scenes/BootScene';
import { MainMenuScene } from './scenes/MainMenuScene';
import { SettingsScene } from './scenes/SettingsScene';
import { GameScene } from './scenes/GameScene';
import { UIScene } from './scenes/UIScene';

new Phaser.Game({
  ...gameConfig,
  scene: [BootScene, MainMenuScene, SettingsScene, GameScene, UIScene],
});
