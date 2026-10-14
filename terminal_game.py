#!/usr/bin/env python3
"""Small interactive terminal version of the 10x12 Game of Life board."""

from __future__ import annotations

import argparse
import os
import random
import select
import sys
import termios
import time
import tty

WIDTH = 12
HEIGHT = 10
MIN_SPEED = 1
MAX_SPEED = 10

SEEDS = (
    (
        "............",
        "............",
        "....##......",
        "....##......",
        "............",
        "............",
        "............",
        "............",
        "............",
        "............",
    ),
    (
        "............",
        "............",
        "...###......",
        "...#........",
        "....#.......",
        "............",
        "............",
        "............",
        "............",
        "............",
    ),
    (
        "............",
        ".....#......",
        "...#.#......",
        "....##......",
        "............",
        "............",
        "............",
        "............",
        "............",
        "............",
    ),
)


def board_from_seed(seed: int) -> list[list[bool]]:
    pattern = SEEDS[seed % len(SEEDS)]
    return [[cell == "#" for cell in row] for row in pattern]


def random_board() -> list[list[bool]]:
    return [[random.choice((False, True)) for _ in range(WIDTH)] for _ in range(HEIGHT)]


def next_generation(board: list[list[bool]]) -> list[list[bool]]:
    result = [[False] * WIDTH for _ in range(HEIGHT)]
    for y in range(HEIGHT):
        for x in range(WIDTH):
            neighbours = sum(
                board[(y + dy) % HEIGHT][(x + dx) % WIDTH]
                for dy in (-1, 0, 1)
                for dx in (-1, 0, 1)
                if dx or dy
            )
            result[y][x] = neighbours == 3 or (board[y][x] and neighbours == 2)
    return result


def render(board: list[list[bool]], generation: int, speed: int, paused: bool, seed: int) -> None:
    cells = "\n".join("".join("██" if cell else "  " for cell in row) for row in board)
    state = "paused" if paused else "running"
    print("\033[H\033[J", end="")
    print("Game of Life - terminal frontend")
    print(f"generation: {generation:04d}  seed: {seed + 1}  speed: {speed}  ({state})")
    print("+" + "-" * (WIDTH * 2) + "+")
    print("|" + cells.replace("\n", "|\n|") + "|")
    print("+" + "-" * (WIDTH * 2) + "+")
    print("q: quit  space: pause  n: next step  r: reset  +/-: speed  1-3: seed  x: random")
    sys.stdout.flush()


def read_key() -> str | None:
    ready, _, _ = select.select([sys.stdin], [], [], 0)
    return sys.stdin.read(1) if ready else None


def run(seed: int) -> None:
    board = board_from_seed(seed)
    generation = 0
    speed = 5
    paused = False
    delay = 1.0 / speed

    if not sys.stdin.isatty():
        raise RuntimeError("The terminal frontend needs an interactive terminal.")

    old_settings = termios.tcgetattr(sys.stdin)
    tty.setcbreak(sys.stdin.fileno())
    try:
        while True:
            render(board, generation, speed, paused, seed)
            started = time.monotonic()
            while time.monotonic() - started < delay:
                key = read_key()
                if key is None:
                    time.sleep(0.02)
                    continue
                if key == "q":
                    return
                if key == " ":
                    paused = not paused
                elif key == "n":
                    board = next_generation(board)
                    generation += 1
                elif key == "r":
                    board = board_from_seed(seed)
                    generation = 0
                elif key == "x":
                    board = random_board()
                    generation = 0
                elif key in "+=":
                    speed = min(MAX_SPEED, speed + 1)
                    delay = 1.0 / speed
                elif key == "-":
                    speed = max(MIN_SPEED, speed - 1)
                    delay = 1.0 / speed
                elif key in "123":
                    seed = int(key) - 1
                    board = board_from_seed(seed)
                    generation = 0
                if not paused and key not in (" ", "n", "r", "x", "+", "=", "-", "1", "2", "3"):
                    break
            if not paused:
                board = next_generation(board)
                generation += 1
    finally:
        termios.tcsetattr(sys.stdin, termios.TCSADRAIN, old_settings)
        print()


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--seed", type=int, choices=range(1, len(SEEDS) + 1), default=1)
    args = parser.parse_args()
    run(args.seed - 1)


if __name__ == "__main__":
    main()
