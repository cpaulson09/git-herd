#!/usr/bin/env bash
# Links git-herd into ~/.local/bin, so git runs it as `git herd`.
set -euo pipefail

src="$(cd "$(dirname "$0")" && pwd)/git-herd"
dest="$HOME/.local/bin/git-herd"

mkdir -p "$(dirname "$dest")"
if [ -L "$dest" ] && [ "$(readlink "$dest")" = "$src" ]; then
  echo "ok      $dest"
else
  ln -sfn "$src" "$dest"
  echo "linked  $dest"
fi

case ":$PATH:" in
  *":$HOME/.local/bin:"*) ;;
  *) echo "Add ~/.local/bin to your PATH, then run: git herd" ;;
esac
for tool in gh fzf; do
  command -v "$tool" >/dev/null || echo "Missing $tool: brew install $tool"
done
