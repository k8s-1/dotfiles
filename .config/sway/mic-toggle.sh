#!/bin/sh
wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle
if wpctl get-volume @DEFAULT_AUDIO_SOURCE@ | grep -q MUTED; then
  msg="MUTED"
  icon=microphone-sensitivity-muted
else
  msg="UNMUTED"
  icon=microphone-sensitivity-high
fi
notify-send -t 1500 -i "$icon" -h string:x-dunst-stack-tag:mic "$msg"
