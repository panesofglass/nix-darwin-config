#!/usr/bin/env bash
set -euo pipefail

# ── Migration script: Homebrew/asdf → nix-darwin ─────────────────────────
#
# Run this AFTER `darwin-rebuild switch --flake ~/nix-config` succeeds
# and you've verified nix-provided tools work.
#
# This script is idempotent — safe to run multiple times.

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

info()  { echo -e "${GREEN}[✓]${NC} $1"; }
warn()  { echo -e "${YELLOW}[!]${NC} $1"; }
skip()  { echo -e "    $1 — skipping"; }

# ── Step 0: Preflight checks ────────────────────────────────────────────
echo ""
echo "═══════════════════════════════════════════════════════════════"
echo "  Homebrew / asdf → nix-darwin migration"
echo "═══════════════════════════════════════════════════════════════"
echo ""

# Verify nix-provided binaries are on PATH
MISSING=()
for cmd in git node ruby python3 go rustup elixir terraform packer aws az gh jq sops age; do
  if ! command -v "$cmd" &>/dev/null; then
    MISSING+=("$cmd")
  elif [[ "$(command -v "$cmd")" != /nix/store/* ]] && [[ "$(command -v "$cmd")" != /run/current-system/* ]]; then
    # On nix-darwin, binaries are symlinked through /run/current-system/sw/bin
    resolved=$(readlink -f "$(command -v "$cmd")" 2>/dev/null || true)
    if [[ "$resolved" != /nix/store/* ]]; then
      warn "$cmd is NOT provided by nix ($(command -v "$cmd"))"
    fi
  fi
done

if [[ ${#MISSING[@]} -gt 0 ]]; then
  echo -e "${RED}[✗] Missing commands: ${MISSING[*]}${NC}"
  echo "    Run 'darwin-rebuild switch --flake ~/nix-config' first."
  exit 1
fi

info "Nix-provided binaries verified on PATH"
echo ""

# ── Step 1: Remove Homebrew formulae now provided by nix ────────────────
echo "── Step 1: Uninstall Homebrew formulae replaced by nix ──"
echo ""

# These are the brew formulae that nix-darwin now provides.
# Casks and brews still managed by homebrew.brews/casks are NOT listed here.
BREW_TO_REMOVE=(
  asdf
  autoconf automake bison cmake meson scons swig
  coreutils curl wget
  fd fzf ripgrep jq gnu-sed grep
  git gnupg subversion
  go rust rustup
  node nvm
  rbenv ruby-build   # Note: ryanfreeform still needs rbenv for Ruby 2.7 (provided by nix home-manager)
  pyenv pyenv-virtualenv python-setuptools "python@3.11" "python@3.12"
  elixir erlang
  awscli azure-cli
  terraform packer sops age
  neovim tmux starship lazygit
  gh httpie lftp inetutils
  imagemagick ghostscript pandoc poppler graphviz
  postgresql flyway dolt
  nats-server watchman
  llvm luarocks pnpm yarn uv
  unar unixodbc libpq fop
  tree-sitter
  help2man
  kdoctor
)

for pkg in "${BREW_TO_REMOVE[@]}"; do
  if brew list --formula "$pkg" &>/dev/null; then
    echo -n "  Uninstalling brew formula: $pkg ... "
    brew uninstall --ignore-dependencies "$pkg" 2>/dev/null && echo "done" || echo "failed (may have dependents)"
  fi
done

info "Homebrew formula cleanup complete"
echo ""

# ── Step 2: Remove asdf plugins and installation ────────────────────────
echo "── Step 2: Remove asdf plugins and installation ──"
echo ""

if command -v asdf &>/dev/null || [[ -d "$HOME/.asdf" ]]; then
  ASDF_PLUGINS=(age awscli elixir erlang github-cli jq packer postgres sops terraform)
  for plugin in "${ASDF_PLUGINS[@]}"; do
    if asdf plugin list 2>/dev/null | grep -q "^${plugin}$"; then
      echo -n "  Removing asdf plugin: $plugin ... "
      asdf plugin remove "$plugin" 2>/dev/null && echo "done" || echo "failed"
    fi
  done

  warn "asdf data directory remains at ~/.asdf"
  warn "Remove it manually once you're confident: rm -rf ~/.asdf"
else
  skip "asdf not found"
fi

info "asdf cleanup complete"
echo ""

# ── Step 2b: Remove SDKMAN ──────────────────────────────────────────────
echo "── Step 2b: Remove SDKMAN (Java now provided by nix) ──"
echo ""

if [[ -d "$HOME/.sdkman" ]]; then
  warn "~/.sdkman directory found"
  warn "Remove it manually once you're confident: rm -rf ~/.sdkman"
else
  skip "SDKMAN not found"
fi

echo ""

# ── Step 3: Remove version manager artifacts ────────────────────────────
echo "── Step 3: Clean up version manager dotfiles ──"
echo ""

remove_if_exists() {
  if [[ -e "$1" ]]; then
    echo -n "  Removing $1 ... "
    rm -rf "$1" && echo "done"
  fi
}

# nvm
remove_if_exists "$HOME/.nvmrc"
warn "~/.nvm directory remains — remove manually: rm -rf ~/.nvm"

# rbenv
remove_if_exists "$HOME/.ruby-version"
warn "~/.rbenv directory remains — remove manually: rm -rf ~/.rbenv"

# pyenv
remove_if_exists "$HOME/.python-version"
warn "~/.pyenv directory remains — remove manually: rm -rf ~/.pyenv"

info "Dotfile cleanup complete"
echo ""

# ── Step 4: Clean up shell RC files ─────────────────────────────────────
echo "── Step 4: Shell RC file review ──"
echo ""
echo "  home-manager now manages your shell config."
echo "  After 'darwin-rebuild switch', back up and remove these files:"
echo "    rm ~/.zshrc ~/.zshenv ~/.zprofile"
echo "  (home-manager will generate new ones)"
echo ""
echo "  If you need to keep them temporarily, check for lines related to:"
echo "    - nvm   (NVM_DIR, nvm.sh, nvm bash_completion)"
echo "    - rbenv  (rbenv init)"
echo "    - pyenv  (PYENV_ROOT, pyenv init)"
echo "    - asdf   (asdf.sh, asdf completions)"
echo "    - sdkman (SDKMAN_DIR, sdkman-init.sh)"
echo ""
echo "  Files to check:"
for rc in ~/.zshrc ~/.zprofile ~/.zshenv ~/.bashrc ~/.bash_profile; do
  if [[ -f "$rc" ]]; then
    hits=$(grep -c -E 'nvm|rbenv|pyenv|asdf|sdkman' "$rc" 2>/dev/null || true)
    if [[ "$hits" -gt 0 ]]; then
      warn "$rc — $hits lines reference version managers"
    else
      info "$rc — clean"
    fi
  fi
done

echo ""

# ── Step 5: Homebrew cleanup ────────────────────────────────────────────
echo "── Step 5: Homebrew dependency cleanup ──"
echo ""
echo -n "  Running brew autoremove ... "
brew autoremove 2>/dev/null && echo "done" || echo "skipped"
echo -n "  Running brew cleanup ... "
brew cleanup 2>/dev/null && echo "done" || echo "skipped"

info "Homebrew cleanup complete"
echo ""

# ── Summary ─────────────────────────────────────────────────────────────
echo "═══════════════════════════════════════════════════════════════"
echo "  Migration complete!"
echo ""
echo "  Manual steps remaining:"
echo "    1. Back up and remove old shell RC files:"
echo "       cp ~/.zshrc ~/.zshrc.bak && cp ~/.zshenv ~/.zshenv.bak && cp ~/.zprofile ~/.zprofile.bak"
echo "       rm ~/.zshrc ~/.zshenv ~/.zprofile"
echo "    2. Remove data directories when ready:"
echo "       rm -rf ~/.nvm ~/.rbenv ~/.pyenv ~/.asdf ~/.sdkman"
echo "    3. Restart your terminal"
echo "═══════════════════════════════════════════════════════════════"
