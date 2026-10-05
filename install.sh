#!/usr/bin/env bash
# Installs git-herd into ~/.local/bin, so git runs it as `git herd`.
#
# From a clone:   ./install.sh            links the clone's git-herd (git pull updates it)
# Without one:    curl -fsSL https://raw.githubusercontent.com/cpaulson09/git-herd/main/install.sh | bash
#                 downloads git-herd (run the same command again to update)
set -euo pipefail

url="https://raw.githubusercontent.com/cpaulson09/git-herd/main/git-herd"
dest="$HOME/.local/bin/git-herd"
here="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" 2>/dev/null && pwd || true)"

mkdir -p "$(dirname "$dest")"
if [ -n "$here" ] && [ -f "$here/git-herd" ]; then
  src="$here/git-herd"
  if [ -L "$dest" ] && [ "$(readlink "$dest")" = "$src" ]; then
    echo "ok      $dest"
  else
    ln -sfn "$src" "$dest"
    echo "linked  $dest -> $src"
  fi
else
  tmp="$(mktemp)"
  curl -fsSL "$url" -o "$tmp"
  head -1 "$tmp" | grep -q '^#!/bin/zsh' || { echo "Download failed: $url" >&2; rm -f "$tmp"; exit 1; }
  rm -f "$dest"   # may be a link from an earlier clone install
  mv "$tmp" "$dest"
  chmod 755 "$dest"
  echo "installed $dest"
fi

case ":$PATH:" in
  *":$HOME/.local/bin:"*) ;;
  *) echo "Add ~/.local/bin to your PATH, then run: git herd" ;;
esac
for tool in gh fzf; do
  command -v "$tool" >/dev/null || echo "Missing $tool: brew install $tool"
done
command -v gh >/dev/null && ! gh auth status >/dev/null 2>&1 && echo "Sign in for PR status: gh auth login"
echo "Run: git herd"
