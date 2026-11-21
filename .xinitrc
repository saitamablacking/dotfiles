setxkbmap br abnt2
export GTK_THEME="Adwaita:dark"

# audio no maximo a cada entrada no dwm (card pelo nome "PCH", tolera codec demorando)
for _i in 1 2 3 4 5 6 7 8 9 10; do
    amixer -c PCH sset Master 100% unmute >/dev/null 2>&1 && break
    sleep 0.3
done

# microfone (entrada traseira) pronto a cada entrada no dwm
amixer -c PCH sset 'Input Source' 'Rear Mic' >/dev/null 2>&1
amixer -c PCH sset Capture 100% cap >/dev/null 2>&1
amixer -c PCH sset 'Rear Mic Boost' 0 >/dev/null 2>&1

feh --bg-scale ~/Imagens/wall.*
~/.local/bin/dwm-status.sh &
exec dbus-run-session -- dwm
