# dotfiles — Artix Linux + dinit + dwm

Setup mínimo e de baixa latência em **Artix Linux** (sem systemd, init **dinit**), kernel
**linux-zen**, **X11 puro + dwm sem compositor** (nada de picom em execução), **ALSA puro**
(sem PulseAudio/PipeWire), zram como swap e `mq-deadline` como scheduler de I/O.

A sessão é iniciada por `startx` → `.xinitrc`, que aplica o teclado ABNT2, desenha o wallpaper
com `feh`, sobe o `dwm-status.sh` (status de CPU/RAM/SWAP/GPU/hora na barra) e faz `exec dwm`.

## Hardware de referência

Este setup foi feito para uma máquina com **GPU Radeon HD 6670 (chip Turks, TeraScale 2)**,
que **não suporta Vulkan nem atomic modesetting**. Por isso a escolha de **X11 em vez de
Wayland**: o driver `radeon` legado funciona bem em X11, e ferramentas como `radeontop`
(usada na barra de status) leem a GPU via ioctls DRM sem precisar de Vulkan.

## Conteúdo

| Caminho no repo | Destino | Observação |
|---|---|---|
| `dwm/config.h` | `~/dwm/config.h` | customizado (paleta roxa, barra inferior, binds) |
| `scripts/dwm-status.sh` | `~/.local/bin/dwm-status.sh` | symlink; status da barra via `xsetroot` |
| `scripts/drun.sh` | `~/.local/bin/drun.sh` | symlink; launcher `j4-dmenu-desktop` com o visual do dwm |
| `.xinitrc` | `~/.xinitrc` | teclado, wallpaper, status, `exec dwm` |
| `install.sh` | — | copia, compila e instala tudo |

### st e dmenu: sem customização em `config.h`

Os `config.h` de **st** e **dmenu** neste sistema são **idênticos ao `config.def.h` upstream**
do suckless (verificado por `diff` contra o commit clonado), portanto **não são versionados
aqui** — não há nada para preservar. Pontos que importam:

- **st**: a customização está no **código**, não no `config.h` — o `st.c`/`st.h` têm o patch
  de **scrollback** (`kscrollup`/`kscrolldown`). Ao reinstalar, o repo do st precisa estar
  com esse patch aplicado antes do `make`.
- **dmenu**: a aparência roxa é passada por **linha de comando** no `scripts/drun.sh`
  (`-nb/-nf/-sb/-sf`), não pelo `config.h`. O binário pode ser o upstream puro.

### dwm: o `config.h` depende de patches no código

O `dwm/config.h` usa dois campos que **não existem no dwm upstream**: `refreshrate` (taxa de
atualização para mover/redimensionar) e `baroff` (deslocamento da barra). O `dwm.c` deste
sistema está patchado de acordo (`m->wh -= bh + baroff`, `1000 / refreshrate`). Se você
compilar este `config.h` contra o dwm puro, **a compilação falha** — aplique os patches
correspondentes no repo do dwm primeiro.

> O `dwm/config.h` também hardcoda o caminho `/home/vinicius/.local/bin/drun.sh`. Se o seu
> usuário for outro, ajuste `dmenucmd[]` depois de rodar o `install.sh`.

### Transparência da barra (pseudo, sem compositor)

A barra **não é transparente de verdade** — não há canal alpha e nenhum compositor roda.
O que acontece: o papel de parede do `feh` vive como um *pixmap* na memória do X, registrado
na propriedade `_XROOTPMAP_ID` (ou `ESETROOT_PMAP_ID`/`_XSETROOT_ID`) da root window. O
`drw.c` patcheado:

1. lê essa propriedade (`XGetWindowProperty`) e valida o pixmap (geometria e profundidade,
   sob error handler temporário — pixmap morto degrada, não quebra);
2. copia **só o recorte** que fica atrás da barra, com `XCopyArea`, para o buffer da barra;
3. desenha os textos opacos por cima — o esquema "transparente" é um sentinela:
   `scheme[ColBg].pixel == 0` pula o retângulo de fundo em `drw_text`/`drw_rect`.

Limitações honestas: mostra o **wallpaper**, não janelas atrás; é cópia de pixels, não
composição (tudo aquilo que o canal alpha do patch oficial faria — e que não funciona sem
compositor). A troca de wallpaper é detectada em tempo real via `PropertyNotify` na root,
que invalida o cache e redesenha a barra. Sem wallpaper setado, a barra cai no fundo
sólido do tema (`col_bg`) sem erro. O patch mora no `dwm.c`/`drw.c` (não versionados,
motivo na seção acima) junto com: `hide_vacant_tags` (tags vazias somem da barra, com o
mapeamento de clique corrigido), centralização de janelas flutuantes novas e o fix do
Xft para texto de tags urgentes sobre fundo transparente.

## Instalação

Pré-requisito: as dependências de compilação do suckless e do launcher **já instaladas**
(`base-devel`, `libx11`, `libxft`, `libxinerama`, `freetype2`, `fontconfig`, `j4-dmenu-desktop`,
`xorg-server`, `xorg-xinit`, `xorg-xsetroot`, `feh`, `maim`, `xclip`). Isso **não** é
responsabilidade do `install.sh`.

```bash
# 1. clonar este repo
git clone <url-do-repo> ~/dotfiles

# 2. clonar os fontes do suckless nos caminhos esperados
git clone https://git.suckless.org/dwm    ~/dwm
git clone https://git.suckless.org/st     ~/st
git clone https://git.suckless.org/dmenu  ~/dmenu

# 3. aplicar os patches (scrollback no st; refreshrate/baroff no dwm)
#    -> sem eles o build do dwm/st com estes fontes não fecha

# 4. instalar
cd ~/dotfiles && ./install.sh
```

O `install.sh` copia os `config.h` disponíveis, roda `sudo make clean install` em `~/dwm`,
`~/st` e `~/dmenu`, cria **symlinks** de `~/.local/bin/` para os scripts do repo (editar o
script no repo muda o sistema na hora) e instala o `.xinitrc`
(backup do antigo em `~/.xinitrc.bak`). No fim, basta:

```bash
startx
```

## Binds do dwm

`MODKEY = Super` (`Mod4Mask`). Confirmado lendo o `dwm/config.h` atual.

| Bind | Ação |
|---|---|
| `Super + Enter` | abre terminal (`st`) |
| `Super + d` | abre o launcher (`drun.sh` → `j4-dmenu-desktop`, PATH + apps Flatpak) |
| `Super + Shift + q` | fecha a janela em foco (`killclient`) |
| `Super + j` / `Super + k` | próximo / anterior no foco (`focusstack`) |
| `Super + 1…9` | vai para o workspace (tag) 1…9 |
| `Super + Shift + 1…9` | move a janela para o workspace 1…9 |
| `Super + Ctrl + 1…9` | alterna a visualização do workspace |
| `Super + Ctrl + Shift + 1…9` | alterna a tag da janela |
| `Super + Shift + e` | sai do dwm (`quit`) |
| `Super + Shift + Enter` | promove a janela a master (`zoom`) |
| `Super + b` | mostra/esconde a barra |
| `Super + i` / `Super + u` | aumenta/diminui o número de janelas em master |
| `Super + h` / `Super + l` | diminui/aumenta o fator master (`mfact`) |
| `Super + t` / `s` / `f` | layouts tile / floating / monocle |
| `Super + Space` | cicla layouts |
| `Super + Shift + Space` | alterna flutuante |
| `Super + 0` / `Super + Shift + 0` | vê todas as tags / move para todas |
| `Super + ,` / `.` | foco no monitor anterior / próximo |
| `Super + Shift + ,` / `.` | move a janela para o monitor anterior / próximo |
| `Print` | screenshot de área → clipboard (`maim -s \| xclip`) |
| `Super + clique` | botão 1 move, botão 2 alterna flutuante, botão 3 redimensiona |

## Notas

- `dwm-status.sh` é deliberadamente barato: lê CPU/RAM de `/proc` com builtins do bash,
  usa `printf '%(...)T'` para a hora e mantém **um único** `radeontop` em background
  publicando em arquivos no tmpfs. Sem `radeontop`, o campo GPU simplesmente desaparece.
- Sem compositor: `picom` pode estar instalado, mas **não** é iniciado no `.xinitrc`.
- Layout do teclado: `setxkbmap br abnt2` no `.xinitrc`; console em `/etc/vconsole.conf`.
