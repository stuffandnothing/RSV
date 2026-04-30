#!/bin/bash
if [[ $EUID -ne 0 ]]; then
    read -rp "  Running as user — will install to:
  ~/.local/bin/rsv
  ~/.local/share/bash-completion/completions/rsv
  ~/.config/fish/completions/rsv.fish
  ~/.local/share/zsh/site-functions/_rsv
  I Recommend installing as Root for sudo rsv to work
  Confirm? [y/N]: " confirm
    [[ $confirm =~ ^[Yy]$ ]] || { echo "Cancelled."; exit 1; }

    mkdir -p ~/.local/bin \
             ~/.local/share/bash-completion/completions \
             ~/.config/fish/completions \
             ~/.local/share/zsh/site-functions
    install -m755 rsv      ~/.local/bin/rsv
    install -m644 rsv.bash ~/.local/share/bash-completion/completions/rsv
    install -m644 rsv.fish ~/.config/fish/completions/rsv.fish
    install -m644 rsv.zsh  ~/.local/share/zsh/site-functions/_rsv
    echo "Installed. Make sure ~/.local/bin is in your PATH."
else
    read -rp "  Running as root — will install to:
  /usr/local/bin/rsv
  /usr/share/bash-completion/completions/rsv
  /usr/share/fish/vendor_completions.d/rsv.fish
  /usr/share/zsh/site-functions/_rsv
  Confirm? [y/N]: " confirm
    [[ $confirm =~ ^[Yy]$ ]] || { echo "Cancelled."; exit 1; }

    install -Dm755 rsv      /usr/local/bin/rsv
    install -Dm644 rsv.bash /usr/share/bash-completion/completions/rsv
    install -Dm644 rsv.fish /usr/share/fish/vendor_completions.d/rsv.fish
    install -Dm644 rsv.zsh  /usr/share/zsh/site-functions/_rsv
    echo "Installed."
fi
