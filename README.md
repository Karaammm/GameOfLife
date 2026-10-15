# Game of Life

This repository contains a RISC-V Game of Life assembly program and a standalone
Python terminal frontend. The assembly program was originally made to run on a
custom FPGA board prepared by my university. The Python frontend provides an
easy-to-run terminal version of the game without requiring that hardware.

## Run with Docker
Run these commands from the repository root:

```sh
docker build -t game-of-life .
docker run --rm -it game-of-life
```

## Run directly with Python

From the repository root, run:

```sh
python3 terminal_game.py
```

This requires Python 3.9 or newer and an interactive terminal. The optional
`--seed` argument selects the initial pattern (`1`, `2`, or `3`):

```sh
python3 terminal_game.py --seed 2
```

The frontend renders a 10x12 board. Controls are shown at the bottom of the
terminal while it is running:

- `q` - quit
- `space` - pause or resume
- `n` - advance one generation
- `r` - reset the current seed
- `+` / `-` - increase or decrease speed
- `1`-`3` - select a seed
- `x` - generate a random board

## Build the assembly program

The assembly build requires a RISC-V GNU toolchain with
`riscv64-unknown-linux-gnu-gcc` and `riscv64-unknown-linux-gnu-objcopy`
installed at `/opt/riscv/bin`. From the repository root, run:

```sh
make build_gol
```

This creates `out/gol` and `out/gol.bin`. Remove build output with:

```sh
make clean
```

## Contents

- `gol.s` - the RISC-V assembly source.
- `terminal_game.py` - the interactive terminal frontend.
- `mmio.ld` - the memory map used by the assembly build.
- `Dockerfile` - Python runtime image definition.
- `Makefile` - assembly build rules.

Assembly build output is written to `out/`, which is ignored by Git.
