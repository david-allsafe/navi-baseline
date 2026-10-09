#!/usr/bin/env bash
# Copia as cheats desta máquina para o repo (para depois fazer commit/push).
# Uso: bash recolher.sh
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CHEATS_DIR="$HOME/.local/share/navi/cheats/david"

shopt -s nullglob
CHEATS=("$CHEATS_DIR"/*.cheat)
(( ${#CHEATS[@]} )) || { echo "Sem cheats em $CHEATS_DIR"; exit 1; }

mkdir -p "$REPO_DIR/cheats"
cp -v "${CHEATS[@]}" "$REPO_DIR/cheats/"
echo
echo "Feito. Revê com 'git diff' e depois: git add -A && git commit -m 'Atualiza cheats' && git push"
