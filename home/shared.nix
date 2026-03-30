{ pkgs, ... }:

{
  home.stateVersion = "24.05";

  # ── Shared dotfiles ──────────────────────────────────────────────────
  home.file = {
    ".claude/settings.json".source = ../dotfiles/claude-settings.json;
    ".gitignore_global".source = ../dotfiles/gitignore_global;
  };

  # ── Common environment variables ─────────────────────────────────────
  home.sessionVariables = {
    EDITOR = "nvim";
    VISUAL = "nvim";
    LC_ALL = "en_US.UTF-8";
    ANDROID_HOME = "$HOME/Library/Android/sdk";
    DOTNET_SYSTEM_GLOBALIZATION_INVARIANT = "1";
  };

  # ── Common PATH entries ──────────────────────────────────────────────
  home.sessionPath = [
    "$HOME/.local/bin"
    "$HOME/.dotnet/tools"
    "$HOME/.cargo/bin"
    "$ANDROID_HOME/emulator"
    "$ANDROID_HOME/platform-tools"
  ];

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
  # LazyVim config is symlinked per-user from dotfiles/.
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
    nix-direnv.enable = true;
  };

  # ── Zsh (base settings; initContent stays per-user) ─────────────────
  programs.zsh = {
    enable = true;
    completionInit = "autoload -U compinit && compinit -u";
    shellAliases = {
      rebuild = "sudo darwin-rebuild switch --flake ~/nix-config";
    };
  };
}
