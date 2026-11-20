/* Veja o arquivo LICENSE para direitos autorais e detalhes da licença. */

/* aparência */
static const unsigned int borderpx  = 2;
static const unsigned int refreshrate  = 60; /* taxa de atualização (Hz) para mover/redimensionar janelas */
static const unsigned int snap      = 32;
static const int showbar            = 1;
static const int topbar             = 0; /* barra na parte de baixo da tela */
static const int baroff             = 5; /* deslocamento da barra em pixels (a partir do topo ou do fundo) */
static const char *fonts[]          = { "DejaVu Sans Mono:size=11" };
static const char dmenufont[]       = "DejaVu Sans Mono:size=11";

/* paleta roxa */
static const char col_bg[]          = "#1a1523"; /* fundo (roxo bem escuro) */
static const char col_border[]      = "#31264a"; /* borda de janelas sem foco */
static const char col_fg[]          = "#c9bde4"; /* texto normal (lilás claro) */
static const char col_fg_sel[]      = "#f7f3ff"; /* texto selecionado (quase branco) */
static const char col_accent[]      = "#8b5cf6"; /* destaque roxo (barra ativa e fundo selecionado) */
static const char col_accent2[]     = "#a78bfa"; /* roxo mais claro para detalhes */
static const char *colors[][3]      = {
	/*               fg           bg          borda      */
	[SchemeNorm] = { col_fg,      col_bg,     col_border },
	[SchemeSel]  = { col_fg_sel,  col_accent, col_accent2 },
};

static const char *tags[] = { "1", "2", "3", "4", "5", "6", "7", "8", "9" };

static const Rule rules[] = {
	/* xprop(1): WM_CLASS(STRING) = instance, class; WM_NAME(STRING) = title */
	/* classe     instância   título      máscara de tags  é flutuante  monitor */
	{ "Gimp",     NULL,       NULL,       0,            1,           -1 },
	{ "Firefox",  NULL,       NULL,       1 << 8,       0,           -1 },
{ "Thunar",   NULL,       NULL,       0,            1,           -1 }, /* sempre flutuante */
{ "st-256color", NULL,    NULL,       0,            1,           -1 }, /* sempre flutuante */
};

static const float mfact     = 0.55;
static const int nmaster     = 1;
static const int resizehints = 1;
static const int lockfullscreen = 1;

static const Layout layouts[] = {
	/* símbolo    função de organização */
	{ "[]=",      tile },
	{ "><>",      NULL },
	{ "[M]",      monocle },
};

#define MODKEY Mod4Mask
#define TAGKEYS(KEY,TAG) \
	{ MODKEY,                       KEY,      view,           {.ui = 1 << TAG} }, \
	{ MODKEY|ControlMask,           KEY,      toggleview,     {.ui = 1 << TAG} }, \
	{ MODKEY|ShiftMask,             KEY,      tag,            {.ui = 1 << TAG} }, \
	{ MODKEY|ControlMask|ShiftMask, KEY,      toggletag,      {.ui = 1 << TAG} },

#define STACK(SYM, CMD) { MODKEY, SYM, spawn, SHCMD(CMD) }
/* auxiliar para executar comandos de shell */
#define SHCMD(cmd) { .v = (const char*[]){ "/bin/sh", "-c", cmd, NULL } }

static char dmenumon[2] = "0";
/* o menu do Mod+D mostra comandos do PATH + apps Flatpak, com as cores roxas da barra */
static const char *dmenucmd[] = { "/home/vinicius/.local/bin/drun.sh", NULL };
static const char *termcmd[]  = { "st", "-g", "60x16", NULL }; /* pequeno; dwm centraliza os flutuantes */
static const char *thunarcmd[]  = { "thunar", NULL }; /* gerenciador de arquivos */

static const Key keys[] = {
	/* modificador                  tecla      função           argumento */
	{ MODKEY,                       XK_d,      spawn,          {.v = dmenucmd } },
	{ MODKEY,                       XK_Return, spawn,          {.v = termcmd } },
	{ MODKEY,                       XK_w,      spawn,          {.v = thunarcmd } }, /* thunar flutuante */
	{ MODKEY,                       XK_b,      togglebar,      {0} },
	{ MODKEY,                       XK_j,      focusstack,     {.i = +1 } },
	{ MODKEY,                       XK_k,      focusstack,     {.i = -1 } },
	{ MODKEY,                       XK_i,      incnmaster,     {.i = +1 } },
	{ MODKEY,                       XK_u,      incnmaster,     {.i = -1 } },
	{ MODKEY,                       XK_h,      setmfact,       {.f = -0.05} },
	{ MODKEY,                       XK_l,      setmfact,       {.f = +0.05} },
	{ MODKEY|ShiftMask,             XK_Return, zoom,           {0} },
	{ MODKEY,                       XK_Tab,    view,           {0} },
	{ MODKEY|ShiftMask,             XK_q,      killclient,     {0} },
	{ MODKEY,                       XK_t,      setlayout,      {.v = &layouts[0]} },
	{ MODKEY,                       XK_s,      setlayout,      {.v = &layouts[1]} },
	{ MODKEY,                       XK_f,      setlayout,      {.v = &layouts[2]} },
	{ MODKEY,                       XK_space,  setlayout,      {0} },
	{ MODKEY|ShiftMask,             XK_space,  togglefloating, {0} },
	{ MODKEY,                       XK_0,      view,           {.ui = ~0 } },
	{ MODKEY|ShiftMask,             XK_0,      tag,            {.ui = ~0 } },
	{ MODKEY,                       XK_comma,  focusmon,       {.i = -1 } },
	{ MODKEY,                       XK_period, focusmon,       {.i = +1 } },
	{ MODKEY|ShiftMask,             XK_comma,  tagmon,         {.i = -1 } },
	{ MODKEY|ShiftMask,             XK_period, tagmon,         {.i = +1 } },
	TAGKEYS(                        XK_1,                      0)
	TAGKEYS(                        XK_2,                      1)
	TAGKEYS(                        XK_3,                      2)
	TAGKEYS(                        XK_4,                      3)
	TAGKEYS(                        XK_5,                      4)
	TAGKEYS(                        XK_6,                      5)
	TAGKEYS(                        XK_7,                      6)
	TAGKEYS(                        XK_8,                      7)
	TAGKEYS(                        XK_9,                      8)
/* captura de tela: tecla Print seleciona a área e copia pra área de transferência */
	{ 0,                           XK_Print,  spawn,          SHCMD("maim -s | xclip -selection clipboard -t image/png") },
	{ MODKEY|ShiftMask,             XK_e,      quit,           {0} },
};

static const Button buttons[] = {
	/* clique              máscara de evento  botão           função           argumento */
	{ ClkLtSymbol,          0,              Button1,        setlayout,      {0} },
	{ ClkLtSymbol,          0,              Button3,        setlayout,      {.v = &layouts[2]} },
	{ ClkWinTitle,          0,              Button2,        zoom,           {0} },
	{ ClkStatusText,        0,              Button2,        spawn,          {.v = termcmd } },
	{ ClkClientWin,         MODKEY,         Button1,        movemouse,      {0} },
	{ ClkClientWin,         MODKEY,         Button2,        togglefloating, {0} },
	{ ClkClientWin,         MODKEY,         Button3,        resizemouse,    {0} },
	{ ClkTagBar,            0,              Button1,        view,           {0} },
	{ ClkTagBar,            0,              Button3,        toggleview,     {0} },
	{ ClkTagBar,            MODKEY,         Button1,        tag,            {0} },
	{ ClkTagBar,            MODKEY,         Button3,        toggletag,      {0} },
};
