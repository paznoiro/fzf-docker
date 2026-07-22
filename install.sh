#!/usr/bin/env bash
#
# fzf-docker installer - works on macOS and Linux
#
# Usage:
#   curl -fsSL https://raw.githubusercontent.com/paznoiro/fzf-docker/master/install.sh | bash
#
set -e

REPO_RAW_URL="https://raw.githubusercontent.com/paznoiro/fzf-docker/master"
INSTALL_DIR="${FZF_DOCKER_INSTALL_DIR:-$HOME/.fzf-docker}"
INSTALL_FILE="$INSTALL_DIR/docker-fzf"

info() { printf "\033[32m%s\033[0m\n" "$1"; }
warn() { printf "\033[33m%s\033[0m\n" "$1"; }
error() { printf "\033[31m%s\033[0m\n" "$1" >&2; }

command_exists() { command -v "$1" > /dev/null 2>&1; }

sudo_if_needed() {
  if [ "$(id -u)" -eq 0 ]; then
    "$@"
  elif command_exists sudo; then
    sudo "$@"
  else
    error "Need root privileges to run: $*"
    return 1
  fi
}

install_fzf_with_package_manager() {
  if command_exists brew; then
    info "Installing fzf with Homebrew..."
    brew install fzf
  elif command_exists apt-get; then
    info "Installing fzf with apt-get..."
    sudo_if_needed apt-get update && sudo_if_needed apt-get install -y fzf
  elif command_exists dnf; then
    info "Installing fzf with dnf..."
    sudo_if_needed dnf install -y fzf
  elif command_exists yum; then
    info "Installing fzf with yum..."
    sudo_if_needed yum install -y fzf
  elif command_exists pacman; then
    info "Installing fzf with pacman..."
    sudo_if_needed pacman -Sy --noconfirm fzf
  elif command_exists zypper; then
    info "Installing fzf with zypper..."
    sudo_if_needed zypper install -y fzf
  elif command_exists apk; then
    info "Installing fzf with apk..."
    sudo_if_needed apk add fzf
  else
    return 1
  fi
}

install_fzf_from_git() {
  if ! command_exists git; then
    return 1
  fi
  info "Installing fzf from source (git)..."
  rm -rf "$HOME/.fzf"
  git clone --depth 1 https://github.com/junegunn/fzf.git "$HOME/.fzf"
  "$HOME/.fzf/install" --bin --no-update-rc --no-key-bindings --no-completion
  if ! command_exists fzf && [ -x "$HOME/.fzf/bin/fzf" ]; then
    warn "fzf was installed to $HOME/.fzf/bin - make sure it is in your PATH"
  fi
}

install_fzf() {
  if command_exists fzf; then
    info "fzf is already installed ($(fzf --version))"
    return 0
  fi

  install_fzf_with_package_manager || install_fzf_from_git || {
    error "Could not install fzf automatically. Please install it manually: https://github.com/junegunn/fzf#installation"
    exit 1
  }

  if command_exists fzf; then
    info "fzf installed successfully ($(fzf --version))"
  fi
}

check_dependency() {
  if command_exists "$1"; then
    info "$1 is installed"
  else
    warn "$1 is NOT installed - fzf-docker requires it. See: $2"
  fi
}

download_docker_fzf() {
  info "Downloading docker-fzf to $INSTALL_FILE..."
  mkdir -p "$INSTALL_DIR"
  if command_exists curl; then
    curl -fsSL "$REPO_RAW_URL/docker-fzf" -o "$INSTALL_FILE"
  elif command_exists wget; then
    wget -qO "$INSTALL_FILE" "$REPO_RAW_URL/docker-fzf"
  else
    error "Neither curl nor wget found. Please install one of them and retry."
    exit 1
  fi
  chmod +x "$INSTALL_FILE"
}

add_source_line() {
  local rc_file="$1"
  local source_line="source $INSTALL_FILE"

  touch "$rc_file"
  if grep -qF "$source_line" "$rc_file"; then
    info "Already sourced in $rc_file"
  else
    printf '\n# fzf-docker\n%s\n' "$source_line" >> "$rc_file"
    info "Added '$source_line' to $rc_file"
  fi
}

setup_shell() {
  case "$(basename "$SHELL")" in
    zsh)  add_source_line "$HOME/.zshrc" ;;
    bash) add_source_line "$HOME/.bashrc" ;;
    *)
      warn "Unknown shell '$SHELL'."
      add_source_line "$HOME/.bashrc"
      [ -f "$HOME/.zshrc" ] && add_source_line "$HOME/.zshrc"
      ;;
  esac
}

main() {
  info "Installing fzf-docker..."
  echo

  install_fzf
  check_dependency docker "https://docs.docker.com/get-docker/"
  check_dependency docker-compose "https://docs.docker.com/compose/install/"
  echo

  download_docker_fzf
  setup_shell
  echo

  info "Installation complete! Open a new terminal (or run: source $INSTALL_FILE) and try: dr, dl, de, dcu, ..."
}

main "$@"
