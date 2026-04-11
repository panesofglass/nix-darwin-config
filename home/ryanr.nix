{ pkgs, ... }:

{
  imports = [ ./shared.nix ];

  # ── Dotfiles (ryanr-specific) ────────────────────────────────────────
  home.file = {
    ".config/nvim" = {
      source = ../dotfiles/nvim;
      recursive = true;
    };
    ".cloudflared/config.yml".text = ''
      tunnel: acd4e71f-dee0-4716-be46-95d4213d69e0
      credentials-file: /Users/ryanr/.cloudflared/acd4e71f-dee0-4716-be46-95d4213d69e0.json

      ingress:
        - hostname: ssh.panesofglass.org
          service: ssh://localhost:22
        - service: http_status:404
    '';
  };

  # ── Additional PATH entries ──────────────────────────────────────────
  home.sessionPath = [
    "$HOME/.lmstudio/bin"
  ];

  # ── SSH (replaces ~/.ssh/config) ─────────────────────────────────────
  programs.ssh = {
    enable = true;
    enableDefaultConfig = false;
    matchBlocks = {
      "*" = {
        extraOptions = {
          AddKeysToAgent = "yes";
          UseKeychain = "yes";
        };
      };
      "github.com" = {
        hostname = "github.com";
        user = "git";
        identityFile = "~/.ssh/id_ed25519";
        identitiesOnly = true;
      };
    };
  };

  # ── Git (replaces ~/.gitconfig) ──────────────────────────────────────
  programs.git = {
    enable = true;
    signing = {
      key = "~/.ssh/id_ed25519.pub";
      format = "ssh";
      signByDefault = true;
    };
    settings = {
      user.name = "Ryan Riley";
      user.email = "ryanriley@live.com";
      core.editor = "nvim";
      credential."https://github.com".helper = "!gh auth git-credential";
      credential."https://gist.github.com".helper = "!gh auth git-credential";
      core.excludesFile = "~/.gitignore_global";
    };
  };

  # ── Zsh (ryanr-specific initContent) ────────────────────────────────
  programs.zsh.initContent = ''
    # Pin SSH to macOS system agent, not 1Password (remove to restore 1Password)
    _sys_sock=$(launchctl asuser "$(id -u)" launchctl getenv SSH_AUTH_SOCK 2>/dev/null)
    [ -n "$_sys_sock" ] && export SSH_AUTH_SOCK="$_sys_sock"
    unset _sys_sock

    # Cargo env (for rustup-managed toolchains)
    [[ -f "$HOME/.cargo/env" ]] && source "$HOME/.cargo/env"
  '';
}
