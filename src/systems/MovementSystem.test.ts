import { describe, it, expect } from 'vitest';
import { movePlayer } from './MovementSystem';
import { createInitialGameState } from '../data/types';

describe('movePlayer', () => {
  it('moves right when right is pressed', () => {
    const state = createInitialGameState();
    const next = movePlayer(state, { left: false, right: true, up: false, down: false }, 1000);
    expect(next.player.position.x).toBeGreaterThan(state.player.position.x);
    expect(next.player.position.y).toBe(state.player.position.y);
  });

  it('moves left when left is pressed', () => {
    const state = createInitialGameState();
    const next = movePlayer(state, { left: true, right: false, up: false, down: false }, 1000);
    expect(next.player.position.x).toBeLessThan(state.player.position.x);
  });

  it('moves up when up is pressed', () => {
    const state = createInitialGameState();
    const next = movePlayer(state, { left: false, right: false, up: true, down: false }, 1000);
    expect(next.player.position.y).toBeLessThan(state.player.position.y);
  });

  it('normalises diagonal so it is slower than cardinal', () => {
    const state = createInitialGameState();
    const diagonal = movePlayer(state, { left: false, right: true, up: false, down: true }, 1000);
    const cardinal = movePlayer(state, { left: false, right: true, up: false, down: false }, 1000);
    const diagX = diagonal.player.position.x - state.player.position.x;
    const cardX = cardinal.player.position.x - state.player.position.x;
    expect(diagX).toBeLessThan(cardX);
  });

  it('does not mutate the input state', () => {
    const state = createInitialGameState();
    const originalX = state.player.position.x;
    movePlayer(state, { left: false, right: true, up: false, down: false }, 1000);
    expect(state.player.position.x).toBe(originalX);
  });

  it('returns a new state object', () => {
    const state = createInitialGameState();
    const next = movePlayer(state, { left: false, right: true, up: false, down: false }, 1000);
    expect(next).not.toBe(state);
  });
});
