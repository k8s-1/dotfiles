#!/bin/sh
# Usage: volume.sh up|down

# Max volume per output type. 1.0 = 100%, 0.3 = 30%.
MAX_VOLUME_BLUETOOTH=0.4
MAX_VOLUME_DEFAULT=1.0

# How much each key press changes the volume, in percent.
STEP=2

case "$1" in
    up)
        if wpctl inspect @DEFAULT_AUDIO_SINK@ | grep -q 'node.name = .bluez_output'; then
            max=$MAX_VOLUME_BLUETOOTH
        else
            max=$MAX_VOLUME_DEFAULT
        fi
        wpctl set-volume -l "$max" @DEFAULT_AUDIO_SINK@ "${STEP}%+"
        ;;
    down)
        wpctl set-volume @DEFAULT_AUDIO_SINK@ "${STEP}%-"
        ;;
esac
