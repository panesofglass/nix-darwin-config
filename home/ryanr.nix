{ pkgs, ... }:

{
  home.stateVersion = "24.05";

  # ── Dotfiles (managed as symlinks) ───────────────────────────────────
  home.file = {
    ".config/nvim" = {
      source = ../dotfiles/nvim;
      recursive = true;
    };
    ".claude/settings.json".source = ../dotfiles/claude-settings.json;
    ".gitignore_global".source = ../dotfiles/gitignore_global;
  };

  # ── Environment variables (replaces .zshenv) ─────────────────────────
  home.sessionVariables = {
    EDITOR = "nvim";
    VISUAL = "nvim";
    LC_ALL = "en_US.UTF-8";
    ANDROID_HOME = "$HOME/Library/Android/sdk";
    SSH_AUTH_SOCK = "$HOME/Library/Group Containers/2BUA8C4S2C.com.1password/t/agent.sock";
  };

  home.sessionPath = [
    "$HOME/.local/bin"
    "$HOME/.dotnet/tools"
    "$HOME/.lmstudio/bin"
    "$HOME/.cargo/bin"
    "$ANDROID_HOME/emulator"
    "$ANDROID_HOME/platform-tools"
  ];

  # ── SSH (replaces ~/.ssh/config) ─────────────────────────────────────
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
    };
  };

  # ── Git (replaces ~/.gitconfig) ──────────────────────────────────────
  programs.git = {
    enable = true;
    settings = {
      user.name = "Ryan Riley";
      user.email = "ryanriley@live.com";
      core.editor = "nvim";
      # gh auth git-credential — nix provides gh on PATH, no hardcoded asdf path
      credential."https://github.com".helper = "!/run/current-system/sw/bin/gh auth git-credential";
      credential."https://gist.github.com".helper = "!/run/current-system/sw/bin/gh auth git-credential";
      core.excludesFile = "~/.gitignore_global";
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
  # LazyVim config is symlinked from dotfiles/nvim above.
  # We just provide the binary + python provider.
  programs.neovim = {
    enable = true;
    defaultEditor = true;
    withPython3 = true;
  };

  # ── tmux ─────────────────────────────────────────────────────────────
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

  # ── direnv ──────────────────────────────────────────────────────────
  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;   # Caches nix shells for fast reload
  };

  # ── Zsh (replaces .zshrc, .zshenv, .zprofile) ───────────────────────
  programs.zsh = {
    enable = true;
    completionInit = "autoload -U compinit && compinit -u";
    shellAliases = {
      rebuild = "sudo darwin-rebuild switch --flake ~/nix-config";
    };
    initContent = ''
      # Cargo env (for rustup-managed toolchains)
      [[ -f "$HOME/.cargo/env" ]] && source "$HOME/.cargo/env"
    '';
  };

}
