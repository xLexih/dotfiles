alias battery="upower -i /org/freedesktop/UPower/devices/battery_BAT0"
alias battery-info="battery"

wifi_full_restart () {
    sudo ip link set wlo1 down
    sudo rfkill unblock wlan
    sudo ip link set wlo1 up
    sudo systemctl restart NetworkManager
}
