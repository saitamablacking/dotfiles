setxkbmap br abnt2
export GTK_THEME=Adwaita-dark

# audio no maximo a cada entrada no dwm (card pelo nome "PCH", tolera codec demorando)
for _i in 1 2 3 4 5 6 7 8 9 10; do
    amixer -c PCH sset Master 100% unmute >/dev/null 2>&1 && break
    sleep 0.3
done

feh --bg-scale ~/Imagens/wall.*
~/.local/bin/dwm-status.sh &
exec dwm
