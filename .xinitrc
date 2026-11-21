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

# servidor de som (Pulse) p/ apps que exigem PulseAudio (Sober/Flatpak).
# ALSA nativo continua no hardware -- pipewire-alsa NAO esta instalado.
# microfone no slider em 40%: espera o no ALSA existir no PipeWire e aplica.
exec dbus-run-session -- sh -c '
    pipewire 2>>~/.cache/pipewire.log &
    pipewire-pulse 2>>~/.cache/pipewire-pulse.log &
    wireplumber 2>>~/.cache/wireplumber.log &
    for _i in $(seq 60); do
        pactl list short sources 2>/dev/null | grep -q alsa_input && break
        sleep 0.25
    done
    pactl set-source-volume alsa_input.pci-0000_00_1b.0.analog-stereo 40% 2>/dev/null
    exec dwm
'
