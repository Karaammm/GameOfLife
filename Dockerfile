FROM ubuntu:24.04

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        libdw1 \
        libelf1 \
        libstdc++6 \
        coreutils \
    && rm -rf /var/lib/apt/lists/*

COPY Vtb /usr/local/bin/game-of-life
RUN chmod 0555 /usr/local/bin/game-of-life

CMD ["/usr/local/bin/game-of-life"]
