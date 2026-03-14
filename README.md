# nix-darwin-config

nix-darwin system configuration for Ryans-Mac-mini (aarch64-darwin), managing two user accounts via home-manager.

**Origin:** `git@github.com:panesofglass/nix-darwin-config.git`

## Structure

```
nix-config/
├── flake.nix                          # Entry point — nixpkgs, nix-darwin, home-manager inputs
├── hosts/
│   └── default.nix                    # System-wide: packages, homebrew casks, macOS defaults
├── home/
│   ├── ryanr.nix                      # Personal account — git, ssh (1Password), tmux, neovim, zsh
│   └── ryanfreeform.nix               # Work account — git, ssh, tmux, neovim, zsh, rbenv, jdk17
├── dotfiles/
│   ├── nvim/                          # ryanr's LazyVim config (symlinked to ~/.config/nvim)
│   └── nvim-ryanfreeform/             # ryanfreeform's LazyVim config
├── scripts/
│   └── migrate-from-brew.sh           # One-time cleanup of Homebrew/asdf/nvm/rbenv/pyenv/SDKMAN
└── .gitignore
```

## What's managed where

### System-wide (`hosts/default.nix`) — applies to all users

- CLI tools: git, curl, wget, ripgrep, fd, fzf, jq, gh, etc.
- Languages: go, rustup, nodejs 22, python 3.12, elixir, erlang
- Cloud/infra: awscli2, azure-cli, terraform, packer, sops, age
- Editors/terminal: neovim, tmux, starship, lazygit
- Homebrew casks: iTerm2, 1Password CLI, nerd fonts, LM Studio, Entire, etc.
- Homebrew brews (no nix equivalent): azure-functions-core-tools, sqlcmd, claude-squad
- macOS defaults, Touch ID sudo, zsh

### Per-user (`home/*.nix`) — account-specific

| Setting | ryanr | ryanfreeform |
|---------|-------|--------------|
| Git email | ryanriley@live.com | ryan@freeformagency.com |
| SSH github.com | 1Password IdentityAgent | 1Password IdentityAgent (primary), ff_ed25519 (fallback) |
| Java | none | jdk17 (user package) |
| Ruby | none | rbenv + ruby-build (Ruby 2.7 for legacy CocoaPods) |
| Neovim | LazyVim + claudecode, ionide | LazyVim + zenbones theme |
| tmux | catppuccin, vim-tmux-navigator, yank | same |
| LM Studio | on PATH | not on PATH |

## Notes

- **Erlang/Elixir do not require Java.** The BEAM VM is written in C. Java is only needed if using `jinterface` or similar JVM-interop libraries, which is uncommon. JDK 17 is installed only for ryanfreeform's Kotlin/Java projects.
- **Ruby 2.7 is EOL** and not available in nixpkgs. It's managed via rbenv in ryanfreeform's home config for a legacy CocoaPods/React Native project.
- **Mason (neovim)** works fine on nix-darwin (unlike NixOS) because macOS provides a standard C toolchain. LSPs are auto-installed by Mason as usual.
- **Homebrew casks** remain managed by Homebrew but are declared declaratively in `hosts/default.nix` via nix-darwin's `homebrew` module.

## Usage

### First-time setup

```bash
# Bootstrap nix-darwin (first time only)
cd ~/nix-config
/nix/var/nix/profiles/default/bin/nix build nix-darwin#darwin-rebuild && sudo ./result/bin/darwin-rebuild switch --flake .

# After first successful switch, darwin-rebuild is on PATH
sudo darwin-rebuild switch --flake ~/nix-config

# Or use the shorter alias (includes sudo)
rebuild
```

### Day-to-day

```bash
# Edit config, then rebuild
rebuild    # alias for: sudo darwin-rebuild switch --flake ~/nix-config
```

### Rollback

```bash
sudo darwin-rebuild switch --rollback
```

### Multi-account workflow

Both accounts run `darwin-rebuild switch` from their own clone of this repo. The system config is shared; home-manager configs are per-user. Keep repos in sync via git.

```bash
# From ryanfreeform account:
git clone git@github.com:panesofglass/nix-darwin-config.git ~/nix-config
sudo darwin-rebuild switch --flake ~/nix-config
```

## Migration from Homebrew/asdf

After the first successful `darwin-rebuild switch`, run the migration script to clean up old package managers:

```bash
~/nix-config/scripts/migrate-from-brew.sh
```

This removes Homebrew formulae replaced by nix, asdf plugins, and SDKMAN. It scans shell RC files for leftover references and leaves data directories (`~/.nvm`, `~/.pyenv`, etc.) for manual removal.

After migration, back up and remove old shell RC files — home-manager generates new ones:

```bash
cp ~/.zshrc ~/.zshrc.bak && cp ~/.zshenv ~/.zshenv.bak && cp ~/.zprofile ~/.zprofile.bak
rm ~/.zshrc ~/.zshenv ~/.zprofile
```
