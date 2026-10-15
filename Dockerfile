FROM python:3.12-slim

COPY terminal_game.py /usr/local/bin/terminal-game
RUN chmod 0555 /usr/local/bin/terminal-game

CMD ["/usr/local/bin/terminal-game"]
