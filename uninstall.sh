#!/usr/bin/env bash
#
# fzf-docker uninstaller
#
# Usage:
#   curl -fsSL https://raw.githubusercontent.com/paznoiro/fzf-docker/master/uninstall.sh | bash
#
set -e

INSTALL_DIR="${FZF_DOCKER_INSTALL_DIR:-$HOME/.fzf-docker}"
INSTALL_FILE="$INSTALL_DIR/docker-fzf"

info() { printf "\033[32m%s\033[0m\n" "$1"; }
warn() { printf "\033[33m%s\033[0m\n" "$1"; }

remove_source_line() {
  local rc_file="$1"
  local source_line="source $INSTALL_FILE"
  local comment_line="# fzf-docker"

  if [ ! -f "$rc_file" ]; then
    return
  fi

  if grep -qF "$source_line" "$rc_file"; then
    local tmp
    tmp=$(mktemp)
    # remove the source line, the comment above it, and the blank line before them
    grep -vF -e "$source_line" -e "$comment_line" "$rc_file" > "$tmp"
    cat "$tmp" > "$rc_file"
    rm -f "$tmp"
    info "Removed fzf-docker block from $rc_file"
    # collapse repeated blank lines into one
    if [[ "$(uname)" == Darwin ]]; then
      sed -i '' -e '/^$/N;/^\n$/D' "$rc_file"
    else
      sed -i -e '/^$/N;/^\n$/D' "$rc_file"
    fi
  fi
}

uninstall() {
  info "Uninstalling fzf-docker..."
  echo

  local files=(
    "$HOME/.zshrc"
    "$HOME/.bashrc"
    "$HOME/.bash_profile"
    "$HOME/.zprofile"
    "$HOME/.profile"
  )
  for f in "${files[@]}"; do
    remove_source_line "$f"
  done

  if [ -d "$INSTALL_DIR" ]; then
    rm -rf "$INSTALL_DIR"
    info "Removed $INSTALL_DIR"
  fi

  echo
  info "Uninstall complete. fzf-docker has been removed."
}

uninstall "$@"
