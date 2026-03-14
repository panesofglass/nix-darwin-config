{ pkgs, ... }:

{
  home.stateVersion = "24.05";

  # ── Dotfiles (managed as symlinks) ───────────────────────────────────
  home.file = {
    ".config/nvim" = {
      source = ../dotfiles/nvim-ryanfreeform;
      recursive = true;
    };
  };

  # ── Environment variables (replaces .zshenv) ─────────────────────────
  # ── User packages (ryanfreeform-specific) ─────────────────────────────
  home.packages = with pkgs; [
    jdk17          # Java 17 for Kotlin/Java projects
    rbenv          # Ruby 2.7 for legacy CocoaPods (not in nixpkgs)
    ruby-build     # rbenv plugin to install ruby versions
  ];

  home.sessionVariables = {
    EDITOR = "nvim";
    VISUAL = "nvim";
    LC_ALL = "en_US.UTF-8";
    ANDROID_HOME = "$HOME/Library/Android/sdk";
    GEM_HOME = "$HOME/.gem";
    SSH_AUTH_SOCK = "$HOME/Library/Group Containers/2BUA8C4S2C.com.1password/t/agent.sock";
  };

  home.sessionPath = [
    "$HOME/.local/bin"
    "$HOME/.dotnet/tools"
    "$HOME/.cargo/bin"
    "$HOME/.gem/bin"
    "$ANDROID_HOME/emulator"
    "$ANDROID_HOME/platform-tools"
  ];

  # ── SSH (replaces ~/.ssh/config) ─────────────────────────────────────
  # 1Password agent first, ff_ed25519 key as fallback
  programs.ssh = {
    enable = true;
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
    userName = "Ryan Riley";
    userEmail = "ryan@freeformagency.com";
    extraConfig = {
      core.editor = "nvim";
      pull.rebase = false;
    };
  };

  # ── Starship prompt ──────────────────────────────────────────────────
  programs.starship = {
    enable = true;
    enableZshIntegration = true;
  };

  # ── fzf ──────────────────────────────────────────────────────────────
  programs.fzf = {
    enable = true;
    enableZshIntegration = true;
  };

  # ── Neovim ───────────────────────────────────────────────────────────
  programs.neovim = {
    enable = true;
    defaultEditor = true;
    withPython3 = true;
  };

  # ── tmux (same config as ryanr) ─────────────────────────────────────
  programs.tmux = {
    enable = true;
    prefix = "C-Space";
    mouse = true;
    keyMode = "vi";
    baseIndex = 1;
    terminal = "xterm-256color";
    plugins = with pkgs.tmuxPlugins; [
      sensible
      vim-tmux-navigator
      catppuccin
      yank
    ];
    extraConfig = ''
      # True color support
      set-option -sa terminal-overrides ",xterm*:Tc"

      # Shift-Alt vim keys to switch windows
      bind -n M-H previous-window
      bind -n M-L next-window

      # Pane numbering
      set -g pane-base-index 1
      set-option -g renumber-windows on

      # Catppuccin theme
      set -g @catppuccin_flavour 'mocha'

      # Vi copy mode bindings
      bind-key -T copy-mode-vi v send-keys -X begin-selection
      bind-key -T copy-mode-vi C-v send-keys -X rectangle-toggle
      bind-key -T copy-mode-vi y send-keys -X copy-selection-and-cancel

      # Open panes in current directory
      bind '"' split-window -v -c "#{pane_current_path}"
      bind % split-window -h -c "#{pane_current_path}"

      # Detach
      bind C-d detach
    '';
  };

  # ── Zsh (replaces .zshrc, .zshenv, .zprofile) ───────────────────────
  programs.zsh = {
    enable = true;
    shellAliases = {
      rebuild = "darwin-rebuild switch --flake ~/nix-config";
    };
    initExtra = ''
      # Cargo env (for rustup-managed toolchains)
      [[ -f "$HOME/.cargo/env" ]] && source "$HOME/.cargo/env"

      # rbenv for legacy Ruby 2.7 (CocoaPods)
      eval "$(rbenv init - zsh)"
    '';
  };
}
