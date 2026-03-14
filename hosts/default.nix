{ pkgs, ... }:

{
  # ── Nix settings ──────────────────────────────────────────────────────
  nix.settings = {
    experimental-features = [ "nix-command" "flakes" ];
    substituters = [
      "https://cache.nixos.org"
      "https://cache.lix.systems"
    ];
    trusted-public-keys = [
      "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
      "cache.lix.systems:aBnZUw8zA7H35Cz2RyKFVs3H4PlGTLawyY5KRbvJR8o="
    ];
  };

  # Allow unfree packages (1password-cli, etc.)
  nixpkgs.config.allowUnfree = true;

  # ── System packages (replaces Homebrew formulae) ──────────────────────
  environment.systemPackages = with pkgs; [
    # Core tools
    git
    curl
    wget
    coreutils
    gnused
    gnugrep
    ripgrep
    fd
    fzf
    jq
    tree-sitter

    # Editors / terminal
    neovim
    tmux
    starship
    lazygit

    # Languages & runtimes
    go
    rustup
    nodejs_22     # Replaces nvm — pinned to Node 22 LTS
    python312     # Primary Python

    # Language tools
    uv            # Replaces pyenv for Python project/venv management
    pnpm
    yarn
    luarocks
    cmake
    automake
    meson
    scons
    swig
    bison
    llvm

    # Elixir / Erlang
    elixir
    erlang

    # Cloud & infra
    awscli2
    azure-cli
    terraform
    packer
    sops
    age

    # Databases (servers run in Docker)
    libpq         # psql client only
    flyway
    dolt

    # Network / messaging
    nats-server
    httpie
    lftp
    inetutils

    # VCS / Git
    gnupg
    subversion

    # Document / image processing
    imagemagick
    ghostscript
    pandoc
    poppler
    graphviz

    # Archive
    unar

    # Misc CLI
    gh         # GitHub CLI
    watchman
    fop
    unixODBC
  ];

  # ── Homebrew (for casks and formulae not in nixpkgs) ──────────────────
  # nix-darwin can manage Homebrew declaratively
  homebrew = {
    enable = true;
    onActivation = {
      autoUpdate = true;
      cleanup = "zap";  # Remove anything not declared here
    };
    casks = [
      "1password-cli"
      "alt-tab"
      "claude-code"
      "iterm2"
      "lm-studio"
      "powershell"
      "font-fira-code-nerd-font"
      "font-hack-nerd-font"
      "font-jetbrains-mono-nerd-font"
      "entireio/tap/entire"
    ];
    taps = [
      "entireio/tap"
    ];
    # Formulae that don't have good nix equivalents
    brews = [
      "azure-functions-core-tools@4"
      "sqlcmd"
      "claude-squad"
    ];
  };

  # ── macOS system defaults ─────────────────────────────────────────────
  system.defaults = {
    dock.autohide = true;
    finder.AppleShowAllExtensions = true;
    NSGlobalDomain.AppleShowAllExtensions = true;
  };

  # ── Security ──────────────────────────────────────────────────────────
  security.pam.services.sudo_local.touchIdAuth = true;

  # ── Shell ─────────────────────────────────────────────────────────────
  programs.zsh.enable = true;

  # Primary user for homebrew, system defaults, etc.
  system.primaryUser = "ryanr";

  # Users managed by home-manager
  users.users.ryanr = {
    name = "ryanr";
    home = "/Users/ryanr";
  };
  users.users.ryanfreeform = {
    name = "ryanfreeform";
    home = "/Users/ryanfreeform";
  };

  # Used for backwards compatibility
  system.stateVersion = 5;
}
