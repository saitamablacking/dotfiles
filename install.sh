#!/usr/bin/env bash
# install.sh — instala os dotfiles deste repo numa máquina já preparada.
#
# Assume que:
#   - as dependências de compilação (base-devel, libx11, libxft, libxinerama,
#     freetype2, fontconfig, j4-dmenu-desktop, xorg-*) JÁ estão instaladas;
#   - os fontes do suckless foram clonados em ~/dwm, ~/st e ~/dmenu.
# Este script NÃO instala pacotes.
set -euo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BIN="$HOME/.local/bin"

info() { printf '\033[1;35m::\033[0m %s\n' "$*"; }
warn() { printf '\033[1;33m!!\033[0m %s\n' "$*" >&2; }
die()  { printf '\033[1;31mxx\033[0m %s\n' "$*" >&2; exit 1; }

# ---------------------------------------------------------------- 0. checagens
for d in dwm st dmenu; do
    [ -f "$HOME/$d/Makefile" ] || die "~/ $d não parece ser o fonte do suckless (falta Makefile).
   Clone antes de rodar este script:
     git clone https://git.suckless.org/$d ~/$d"
done
[ -f "$REPO/dwm/config.h" ] || die "dwm/config.h não encontrado em $REPO"

# st/dmenu não são versionados aqui quando estão no padrão upstream.
for d in st dmenu; do
    if [ ! -f "$REPO/$d/config.h" ]; then
        info "$d/config.h não está no repo (padrão upstream) — mantendo o config.h atual de ~/$d"
    fi
done

# Avisos sobre patches que o código destes fontes precisa ter.
if ! grep -q 'baroff' "$HOME/dwm/dwm.c" 2>/dev/null; then
    warn "~/dwm/dwm.c não referencia 'baroff'/'refreshrate'. O dwm/config.h deste repo
   depende desses patches (barra deslocada + refreshrate). O build provavelmente vai falhar."
fi
if ! grep -q 'kscrollup' "$HOME/st/st.c" 2>/dev/null; then
    warn "~/st/st.c não tem o patch de scrollback (kscrollup/kscrolldown). O st vai compilar,
   mas o comportamento não será o mesmo do sistema de referência."
fi

# ------------------------------------------------- 1. copiar os config.h
info "Copiando config.h"
cp -v "$REPO/dwm/config.h" "$HOME/dwm/config.h"
for d in st dmenu; do
    if [ -f "$REPO/$d/config.h" ]; then
        cp -v "$REPO/$d/config.h" "$HOME/$d/config.h"
    fi
done

# --------------------------------------- 2. compilar e instalar (dwm/st/dmenu)
for d in dwm st dmenu; do
    info "Compilando e instalando ~/$d"
    ( cd "$HOME/$d" && sudo make clean install )
done

# --------------------------------------------- 3. scripts em ~/.local/bin
info "Instalando scripts em $BIN"
mkdir -p "$BIN"
install -v -m 755 "$REPO/scripts/dwm-status.sh" "$BIN/dwm-status.sh"
install -v -m 755 "$REPO/scripts/drun.sh"       "$BIN/drun.sh"

# ------------------------------------------------------- 4. .xinitrc
if [ -f "$HOME/.xinitrc" ] && ! cmp -s "$REPO/.xinitrc" "$HOME/.xinitrc"; then
    info "Backup do .xinitrc atual em ~/.xinitrc.bak"
    cp -v "$HOME/.xinitrc" "$HOME/.xinitrc.bak"
fi
info "Instalando .xinitrc"
install -v -m 644 "$REPO/.xinitrc" "$HOME/.xinitrc"

# ------------------------------------------------------- 5. mensagem final
cat <<'EOF'

------------------------------------------------------------------
Instalação concluída.

  dwm, st e dmenu compilados e instalados
  scripts em ~/.local/bin/ (dwm-status.sh, drun.sh)
  ~/.xinitrc atualizado

Rode "startx" para aplicar e iniciar a sessão.
------------------------------------------------------------------
EOF
