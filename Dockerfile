FROM ubuntu:24.04

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        libdw1 \
        libelf1 \
        libstdc++6 \
        coreutils \
        python3 \
    && rm -rf /var/lib/apt/lists/*

COPY Vtb /usr/local/bin/game-of-life
COPY terminal_game.py /usr/local/bin/terminal-game
RUN chmod 0555 /usr/local/bin/game-of-life
RUN chmod 0555 /usr/local/bin/terminal-game

CMD ["/usr/local/bin/game-of-life"]
