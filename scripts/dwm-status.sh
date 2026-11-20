#!/bin/bash
# dwm-status.sh: status do dwm via xsetroot -name  ->  "CPU: x% | RAM: y% [ | GPU: z%] | HH:MM"
#
# Projeto de custo mínimo:
#   - CPU e RAM lidos de /proc com read builtin (zero forks por iteração).
#   - Horário via printf '%(...)T' (builtin bash).
#   - Único processo externo por iteração: xsetroot.
#   - GPU: UM único radeontop em background (ele mede ~1x/s, cada spawn custaria
#     ~1s), publicado em arquivos no tmpfs; o loop principal só os lê.
#     Um supervisor relança o radeontop ~5s depois se ele morrer.
#     Sem radeontop (ou com telemetria indisponível): o campo GPU simplesmente
#     some, sem erro e sem travar o script.

rundir="${XDG_RUNTIME_DIR:-/tmp}"
gpuval="$rundir/dwm-status.gpu"
gpuage="$rundir/dwm-status.gpu.age"
pidfile="$rundir/dwm-status.pid"
GPU_TTL=6   # segundos sem atualização até omitir o campo GPU

# evita instância duplicada (ex.: xinitrc rodado duas vezes)
if [ -r "$pidfile" ]; then
    IFS= read -r old < "$pidfile"
    [ -n "$old" ] && kill -0 "$old" 2>/dev/null && exit 0
fi
printf '%s\n' "$$" > "$pidfile"

cleanup() {
    [ -n "$gpujob" ] && kill "$gpujob" 2>/dev/null
    IFS= read -r cur < "$pidfile" 2>/dev/null
    [ "$cur" = "$$" ] && rm -f "$pidfile"
    rm -f "$gpuval" "$gpuage"
}
trap cleanup EXIT INT TERM

# ---- amostrador de GPU (driver radeon legado, TeraScale 2) ----
# radeontop funciona nesse driver via ioctls DRM (não precisa Vulkan).
# Supervisor mantém UM radeontop vivo: lê o stdout dele, publica só o campo
# "gpu" + epoch, e o relança ~5s depois se ele morrer.
if command -v radeontop >/dev/null 2>&1; then
    rm -f "$gpuval" "$gpuage" 2>/dev/null
    ( while :; do
          radeontop -d - -l 0 2>/dev/null | while IFS= read -r line; do
              case $line in
                  *" gpu "*)
                      g=${line##*gpu }   # "65.83%, ee ..."
                      g=${g%%,*}         # "65.83%"
                      printf 'GPU: %.0f%%\n' "$g" > "$gpuval" 2>/dev/null
                      printf '%s\n' "$EPOCHSECONDS" > "$gpuage" 2>/dev/null
                      ;;
              esac
          done
          # radeontop morreu/EOF: limpa para o campo sumir e tenta de novo
          rm -f "$gpuval" "$gpuage" 2>/dev/null
          sleep 5
      done ) &
    gpujob=$!
else
    gpujob=""
fi

# ---- estado para o cálculo delta da CPU ----
prev_total=0 ; prev_idle=0 ; lastcpu=0 ; rampct=0

get_cpu_ram() {
    # CPU: primeira linha do /proc/stat
    local u n s i io irq sirq st idle total dtotal didle
    IFS=' ' read -r _ u n s i io irq sirq st _ < /proc/stat
    idle=$((i + io))
    total=$((u + n + s + i + io + irq + sirq + st))
    if (( prev_total > 0 )); then
        dtotal=$((total - prev_total)) ; didle=$((idle - prev_idle))
        if (( dtotal > 0 )); then
            cpupct=$(( (dtotal - didle) * 100 / dtotal ))
        else
            cpupct=$lastcpu
        fi
    else
        cpupct=0
    fi
    lastcpu=$cpupct ; prev_total=$total ; prev_idle=$idle

    # RAM: MemTotal e MemAvailable; SWAP: SwapTotal e SwapFree do /proc/meminfo
    local k v mt=0 ma=0 st=0 sf=0
    while read -r k v _ ; do
        case $k in
            MemTotal:)     mt=$v ;;
            MemAvailable:) ma=$v ;;
            SwapTotal:)    st=$v ;;
            SwapFree:)     sf=$v ;;
        esac
    done < /proc/meminfo
    (( mt > 0 )) && rampct=$(( (mt - ma) * 100 / mt ))
    swap=""
    if (( st > 0 )); then
        local su=$((st - sf))
        if (( su >= 1048576 )); then   # >= 1 GB (valores em kB)
            swap=$(printf '%d.%dG' $((su / 1048576)) $(( (su % 1048576) * 10 / 1048576 )))
        else
            swap="$((su / 1024))M"
        fi
    fi
}

# ---- loop principal ----
while true; do
    get_cpu_ram

    # GPU: válida só se atualizada há menos de GPU_TTL segundos
    gpu=""
    if [ -r "$gpuval" ] && [ -r "$gpuage" ]; then
        IFS= read -r gage < "$gpuage" 2>/dev/null
        if [ -n "$gage" ] && (( EPOCHSECONDS - gage <= GPU_TTL )); then
            IFS= read -r gpu < "$gpuval" 2>/dev/null
        fi
    fi

    status="CPU: ${cpupct}% | RAM: ${rampct}%"
    [ -n "$swap" ] && status="$status | SWAP: $swap"
    [ -n "$gpu" ] && status="$status | $gpu"
    status="$status | $(printf '%(%H:%M)T' -1)"

    xsetroot -name "$status"
    sleep 2
done
