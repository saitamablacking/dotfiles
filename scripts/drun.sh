#!/bin/sh
# drun.sh: j4-dmenu-desktop com a mesma aparência do dmenu do dwm
# (fonte e cores exatas do config.h: dmenufont, col_bg, col_fg, col_accent, col_fg_sel)
exec j4-dmenu-desktop --dmenu="dmenu -i -m 0 -fn 'DejaVu Sans Mono:size=11' -nb '#1a1523' -nf '#c9bde4' -sb '#8b5cf6' -sf '#f7f3ff'"
