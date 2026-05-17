FROM artixlinux/artixlinux:base-runit

# Update system and install dev tools
RUN pacman -Syu --noconfirm && \
    pacman -S --noconfirm \
        runit \
        bash \
        bash-completion \
        fish \
        zsh \
        vim \
        git \
        procps-ng \
        sudo \
        shadow \
        && pacman -Scc --noconfirm

# System runit dirs
RUN mkdir -p /etc/runit/sv \
             /etc/runit/runsvdir/default \
             /var/log

# Initialize shadow password files before useradd
RUN pwconv && grpconv

# Create a test user for user-mode runit testing
RUN useradd -m -s /bin/bash testuser && \
    echo "testuser ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

# Set up user runit dirs
RUN mkdir -p /home/testuser/.runit/sv \
             /home/testuser/.runit/runsvdir \
             /home/testuser/.runit/log/everything && \
    chown -R testuser:testuser /home/testuser/.runit

# XDG_RUNTIME_DIR needed for user services
RUN mkdir -p /run/user/1000 && \
    chown testuser:testuser /run/user/1000

# Copy entrypoint
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

# rsv repo will be mounted here
VOLUME ["/rsv"]

WORKDIR /rsv

ENTRYPOINT ["/entrypoint.sh"]
