{ pkgs, ... }:

{
  imports = [ ./shared.nix ];

  # ── Dotfiles (ryanfreeform-specific) ─────────────────────────────────
  home.file.".config/nvim" = {
    source = ../dotfiles/nvim-ryanfreeform;
    recursive = true;
  };

  # ── User packages (ryanfreeform-specific) ────────────────────────────
  home.packages = with pkgs; [
    jdk17
    rbenv
  ];

  # ── Additional environment variables ─────────────────────────────────
  home.sessionVariables = {
    GEM_HOME = "$HOME/.gem";
    SSH_AUTH_SOCK = "$HOME/Library/Group Containers/2BUA8C4S2C.com.1password/t/agent.sock";
  };

  # ── Additional PATH entries ──────────────────────────────────────────
  home.sessionPath = [
    "$HOME/.gem/bin"
  ];

  # ── SSH (replaces ~/.ssh/config) ─────────────────────────────────────
  # 1Password agent first, ff_ed25519 key as fallback
  programs.ssh = {
    enable = true;
    enableDefaultConfig = false;
    matchBlocks = {
      "github.com" = {
        hostname = "github.com";
        user = "git";
        extraOptions = {
          IdentityAgent = "\"~/Library/Group Containers/2BUA8C4S2C.com.1password/t/agent.sock\"";
        };
      };
      "github.com-fallback" = {
        hostname = "github.com";
        user = "git";
        identityFile = "~/.ssh/ff_ed25519";
        identitiesOnly = true;
        extraOptions = {
          AddKeysToAgent = "yes";
          UseKeychain = "yes";
        };
      };
    };
  };

  # ── Git (replaces ~/.gitconfig) ──────────────────────────────────────
  programs.git = {
    enable = true;
    settings = {
      user.name = "Ryan Riley";
      user.email = "ryan@freeformagency.com";
      core.editor = "nvim";
      pull.rebase = false;
      core.excludesFile = "~/.gitignore_global";
    };
  };

  # ── Zsh (ryanfreeform-specific initContent) ─────────────────────────
  programs.zsh.initContent = ''
    # Cargo env (for rustup-managed toolchains)
    [[ -f "$HOME/.cargo/env" ]] && source "$HOME/.cargo/env"

    # rbenv for legacy Ruby 2.7 (CocoaPods)
    eval "$(rbenv init - zsh)"
  '';
}
