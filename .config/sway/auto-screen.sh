#!/bin/sh
# Turns the primary screen off/on when an external screen is connected/disconnected.

PRIMARY_DEVICE=eDP-1

count_external() {
    swaymsg -t get_outputs -r |
        jq "[.[] | select(.name != \"$PRIMARY_DEVICE\" and .active)] | length"
}

# Disables or enables the laptop screen depending on the external count.
update_screen() {
    if [ "$(count_external)" -gt 0 ]; then
        swaymsg output "$PRIMARY_DEVICE" disable
    else
        swaymsg output "$PRIMARY_DEVICE" enable
    fi
}

last_count=-1

check() {
    count=$(count_external)
    if [ "$count" != "$last_count" ]; then
        last_count=$count
        update_screen
    fi
}

check

# blocking check until screen change
swaymsg -m -t subscribe '["output"]' | while read -r _event; do
    check
done
