# Game of Life

This repository contains a RISC-V Game of Life program and its prebuilt
Verilator testbench.

## Run with Docker

Install and start Docker Desktop, then run these commands from the repository
root:

```sh
docker build --platform linux/amd64 -t game-of-life .
docker run --rm --platform linux/amd64 -it game-of-life
```

The image targets `linux/amd64` because the included `Vtb` executable is a
Linux x86-64 binary. Docker Desktop supplies emulation when the host is
Apple Silicon.

The simulator is an interactive, long-running process. Stop it with
`Ctrl-C`.

To run it for a fixed duration instead:

```sh
docker run --rm --platform linux/amd64 game-of-life \
  timeout 15s /usr/local/bin/game-of-life
```

An exit status of `124` means the simulator ran for the full timeout.

## Contents

- `gol.s` - the RISC-V assembly source.
- `Vtb` - the prebuilt Verilator testbench.
- `mmio.ld` - the memory map used by the assembly build.
- `Dockerfile` - reproducible runtime image definition.
- `Makefile` - legacy assembly and Verilator build rules.

The HDL and C++ sources used to produce `Vtb` are not included, so the
Docker image runs the checked-in testbench rather than rebuilding it.

## Generated files

The simulator may produce `dump.vcd`, `log.txt`, and `err.log`. These are
runtime artifacts and are not required to build the Docker image.
