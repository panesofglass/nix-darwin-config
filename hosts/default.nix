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

    # Dotnet
    (with dotnetCorePackages; combinePackages [
      sdk_8_0
      sdk_9_0
      sdk_10_0
    ])
    fsautocomplete
    fantomas
    ilspycmd
    powershell

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
    cloudflared

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
    mas        # Mac App Store CLI
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
      # Productivity
      "1password"
      "1password-cli"
      "chatgpt"
      "claude"
      "claude-code"
      "cleanmymac"
      "discord"
      "microsoft-edge"
      "microsoft-teams"
      "signal"
      "slack"
      "zoom"

      # Dev tools
      "docker"
      "iterm2"
      "lm-studio"
      "powershell"
      "visual-studio-code"

      # Utilities
      "alt-tab"
      "rectangle"
      "vlc"

      # Creative / hobby
      "bambu-studio"
      "blender"
      "epic-games"
      "obs"
      "raspberry-pi-imager"
      "steam"
      "unity-hub"

      # Fonts
      "font-fira-code-nerd-font"
      "font-hack-nerd-font"
      "font-jetbrains-mono-nerd-font"

      # Third-party taps
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
  programs.zsh = {
    enable = true;
    # Disable system-level compinit; home-manager runs compinit -u instead.
    # /nix/store is group-writable (nixbld), which compinit flags as insecure.
    # This is safe — the nix store is append-only and daemon-protected.
    enableGlobalCompInit = false;
  };

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

  # ── Cloudflare SSH short-lived certificates ───────────────────────────
  environment.etc."ssh/cloudflare_ca.pub".text =
    "ecdsa-sha2-nistp256 AAAAE2VjZHNhLXNoYTItbmlzdHAyNTYAAAAIbmlzdHAyNTYAAABBBO+lPeLulfRzdZRS5SiyiMkcmqcogKPJi3wFm1VkU1a/HLGzUg7Pe8Bpwa8IixAYc9peI0kBjDyb2szGSdyDzVU= open-ssh-ca@cloudflareaccess.org\n";
  environment.etc."ssh/sshd_config.d/050-cloudflare-ssh-certs.conf".text = ''
    PubkeyAuthentication yes
    TrustedUserCAKeys /etc/ssh/cloudflare_ca.pub
  '';

  # ── Cloudflare Tunnel (SSH) ───────────────────────────────────────────
  launchd.daemons.cloudflared = {
    serviceConfig = {
      Label = "com.cloudflare.cloudflared";
      ProgramArguments = [
        "${pkgs.cloudflared}/bin/cloudflared"
        "tunnel"
        "--config"
        "/Users/ryanr/.cloudflared/config.yml"
        "run"
      ];
      RunAtLoad = true;
      KeepAlive = true;
      ThrottleInterval = 5;
      ProcessType = "Background";
      StandardOutPath = "/var/log/cloudflared.log";
      StandardErrorPath = "/var/log/cloudflared.log";
    };
  };

  # Used for backwards compatibility
  system.stateVersion = 5;
}
