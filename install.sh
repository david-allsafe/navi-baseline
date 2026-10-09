#!/usr/bin/env bash
# navi-baseline: instala o navi, as cheats e as notas numa máquina Linux.
# Uso: bash install.sh
# Idempotente: pode correr várias vezes sem duplicar configuração.
set -euo pipefail

NAVI_VERSION="2.24.0"
REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BIN_DIR="$HOME/.local/bin"
CHEATS_DIR="$HOME/.local/share/navi/cheats/david"
NOTAS_DIR="$HOME/notas"
EXTRA_PKGS=(tealdeer tree libimage-exiftool-perl poppler-utils)

# SHA-256 dos binários oficiais (releases do GitHub, v2.24.0)
declare -A SHA256=(
  [x86_64-unknown-linux-musl]="f334047479241f7c8b48d091f4e814dcc798a51a74dfd04ee63cbf67e8c921ba"
  [aarch64-unknown-linux-gnu]="de99e69906a0e06ffd30a329645e15f9e96a6b42c49eaac8baccac9bc314768a"
  [armv7-unknown-linux-musleabihf]="c43aaf8efcbc1b2a839bcb9750e083b26695a6b107debc38aa6ef0ae7c7a2f58"
)

ok()   { printf '\e[32m[ok]\e[0m %s\n' "$*"; }
info() { printf '\e[34m[..]\e[0m %s\n' "$*"; }
warn() { printf '\e[33m[!!]\e[0m %s\n' "$*"; }
die()  { printf '\e[31m[xx]\e[0m %s\n' "$*" >&2; exit 1; }

[[ $EUID -eq 0 ]] && die "Corre como utilizador normal (sem sudo); o script pede sudo só quando precisa."

# 1. Dependências (apt)
if command -v apt-get >/dev/null; then
  info "A instalar fzf..."
  APT=(sudo DEBIAN_FRONTEND=noninteractive apt-get -y -qq -o Dpkg::Options::=--force-confold)
  "${APT[@]}" update >/dev/null 2>&1 || warn "apt update com avisos (a continuar)"
  "${APT[@]}" install fzf curl >/dev/null || die "Falhou a instalação do fzf (verifica: sudo dpkg --configure -a)"
  for p in "${EXTRA_PKGS[@]}"; do
    "${APT[@]}" install "$p" >/dev/null 2>&1 || warn "Pacote opcional '$p' não instalado"
  done
  ok "Dependências instaladas"
else
  command -v fzf >/dev/null || die "Sem apt: instala o fzf manualmente e volta a correr."
  warn "Sem apt: pacotes opcionais (${EXTRA_PKGS[*]}) não instalados"
fi

# 2. Binário do navi (release oficial, verificado por SHA-256)
if command -v navi >/dev/null; then
  ok "navi já instalado: $(navi --version)"
else
  case "$(uname -m)" in
    x86_64)        TARGET="x86_64-unknown-linux-musl" ;;
    aarch64|arm64) TARGET="aarch64-unknown-linux-gnu" ;;
    armv7l)        TARGET="armv7-unknown-linux-musleabihf" ;;
    *) die "Arquitetura $(uname -m) sem binário; usa: cargo install --locked navi" ;;
  esac
  TMP="$(mktemp -d)"; trap 'rm -rf "$TMP"' EXIT
  URL="https://github.com/denisidoro/navi/releases/download/v${NAVI_VERSION}/navi-v${NAVI_VERSION}-${TARGET}.tar.gz"
  info "A descarregar navi v${NAVI_VERSION} (${TARGET})..."
  curl -fsSL "$URL" -o "$TMP/navi.tar.gz"
  echo "${SHA256[$TARGET]}  $TMP/navi.tar.gz" | sha256sum -c --quiet - \
    || die "SHA-256 não corresponde: download corrompido ou adulterado. Abortado."
  tar -xzf "$TMP/navi.tar.gz" -C "$TMP"
  install -Dm755 "$TMP/navi" "$BIN_DIR/navi"
  export PATH="$BIN_DIR:$PATH"
  ok "navi instalado em $BIN_DIR/navi ($(navi --version))"
fi

# 3. Cheats
mkdir -p "$CHEATS_DIR"
shopt -s nullglob
CHEATS=("$REPO_DIR"/cheats/*.cheat)
if (( ${#CHEATS[@]} )); then
  cp "${CHEATS[@]}" "$CHEATS_DIR/"
  ok "${#CHEATS[@]} cheat(s) copiadas para $CHEATS_DIR"
else
  warn "Pasta cheats/ vazia: corre 'bash recolher.sh' numa máquina já configurada"
fi

# 4. Notas (faz backup se já existirem e forem diferentes)
mkdir -p "$NOTAS_DIR"
if [[ -f "$NOTAS_DIR/01.txt" ]] && ! cmp -s "$REPO_DIR/notas/01.txt" "$NOTAS_DIR/01.txt"; then
  cp "$NOTAS_DIR/01.txt" "$NOTAS_DIR/01.txt.bak.$(date +%Y%m%d%H%M%S)"
  warn "Notas antigas guardadas em ~/notas/01.txt.bak.*"
fi
cp "$REPO_DIR/notas/01.txt" "$NOTAS_DIR/01.txt"
ok "Notas em ~/notas/01.txt"

# 5. Shell (PATH + widget Ctrl+G), só se ainda não estiver configurado
SHELL_NAME="$(basename "${SHELL:-bash}")"
case "$SHELL_NAME" in
  zsh)  RC="${ZDOTDIR:-$HOME}/.zshrc" ;;
  bash) RC="$HOME/.bashrc" ;;
  *) warn "Shell '$SHELL_NAME' não suportada: configura o widget à mão"; RC="" ;;
esac
if [[ -n "$RC" ]]; then
  touch "$RC"
  if grep -q "navi widget" "$RC"; then
    ok "$RC já tem o widget do navi"
  else
    cat >> "$RC" <<EOF

# >>> navi-baseline >>>
export PATH="\$HOME/.local/bin:\$PATH"
eval "\$(navi widget $SHELL_NAME)"
# <<< navi-baseline <<<
EOF
    ok "Widget adicionado a $RC"
  fi
fi

echo
ok "Concluído. Abre um terminal novo (ou: source $RC) e usa 'navi' ou Ctrl+G."
