import { GameState } from '../data/types';

export interface InputState {
  left: boolean;
  right: boolean;
  up: boolean;
  down: boolean;
}

export function movePlayer(state: GameState, input: InputState, delta: number): GameState {
  const speed = state.player.speed;
  const dt = delta / 1000;

  let dx = 0;
  let dy = 0;

  if (input.left) dx -= 1;
  if (input.right) dx += 1;
  if (input.up) dy -= 1;
  if (input.down) dy += 1;

  if (dx !== 0 && dy !== 0) {
    dx /= Math.SQRT2;
    dy /= Math.SQRT2;
  }

  return {
    ...state,
    player: {
      ...state.player,
      position: {
        x: state.player.position.x + dx * speed * dt,
        y: state.player.position.y + dy * speed * dt,
      },
    },
  };
}
