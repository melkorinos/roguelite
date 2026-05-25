export interface Vec2 {
  x: number;
  y: number;
}

export interface PlayerEntity {
  id: 'player';
  position: Vec2;
  speed: number;
  health: number;
}

export interface ItemEntity {
  id: string;
  type: string;
  position: Vec2;
  collected: boolean;
}

export interface GameState {
  player: PlayerEntity;
  items: ItemEntity[];
  tick: number;
}

export function createInitialGameState(): GameState {
  return {
    player: {
      id: 'player',
      position: { x: 400, y: 300 },
      speed: 200,
      health: 100,
    },
    items: [],
    tick: 0,
  };
}
