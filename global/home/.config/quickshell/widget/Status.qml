pragma ComponentBehavior: Bound
import Quickshell
import Quickshell.Io
import Quickshell.Networking
import Quickshell.Services.Pipewire
import Quickshell.Services.UPower
import QtQuick
import "../asset" as Asset

// Brightness (hidden without a backlight), volume, network, and battery or,
// without one, the power profile.
Column {
    id: root

    required property var tooltip

    function duration(seconds) {
        const minutes = Math.round(seconds / 60);
        return minutes >= 60 ? Math.floor(minutes / 60) + "h " + (minutes % 60) + "m" : minutes + "m";
    }

    spacing: 4

    // Brightness: polled, since backlight changes don't send events.
    property int brightness: -1
    property bool hasBacklight: true

    Process {
        id: brightnessRead
        command: ["brightnessctl", "--class=backlight", "--machine-readable", "info"]
        stdout: StdioCollector {
            onStreamFinished: {
                const fields = this.text.trim().split(",");
                root.hasBacklight = fields.length >= 4;
                root.brightness = root.hasBacklight ? parseInt(fields[3]) : -1;
            }
        }
    }

    Process {
        id: brightnessWrite
        onExited: brightnessRead.running = true
    }

    Timer {
        interval: 2000
        repeat: true
        triggeredOnStart: true
        running: root.hasBacklight
        onTriggered: brightnessRead.running = true
    }

    StatusIcon {
        visible: root.brightness >= 0
        tooltip: root.tooltip
        icon: root.brightness < 34 ? "brightness_low" : root.brightness < 67 ? "brightness_medium" : "brightness_high"
        tooltipText: "Brightness " + root.brightness + "%"
        onScrolled: steps => {
            brightnessWrite.command = ["brightnessctl", "--class=backlight", "set", Math.abs(steps) * 5 + (steps > 0 ? "%+" : "%-")];
            brightnessWrite.running = true;
        }
    }

    // Volume of the default output.
    readonly property PwNode sink: Pipewire.defaultAudioSink

    PwObjectTracker {
        objects: root.sink ? [root.sink] : []
    }

    StatusIcon {
        readonly property real volume: root.sink?.audio?.volume ?? 0
        readonly property bool muted: root.sink?.audio?.muted ?? false

        visible: root.sink !== null
        tooltip: root.tooltip
        icon: muted ? "volume_off" : volume < 0.01 ? "volume_mute" : volume < 0.5 ? "volume_down" : "volume_up"
        color: muted ? Asset.Theme.muted : Asset.Theme.secondary
        tooltipText: (root.sink?.description || "Volume") + ": " + Math.round(volume * 100) + "%" + (muted ? ", muted" : "")
        onClicked: button => {
            if (button === Qt.LeftButton)
                root.sink.audio.muted = !muted;
            else
                Quickshell.execDetached(["pwvucontrol"]);
        }
        // Up to 150%, the same limit as swayosd.
        onScrolled: steps => root.sink.audio.volume = Math.max(0, Math.min(1.5, volume + steps * 0.05))
    }

    // Network: wired wins over wifi.
    readonly property var netDevices: Networking.devices.values
    readonly property var wired: netDevices.find(device => device.type === DeviceType.Wired && device.connected) ?? null
    readonly property var wifi: {
        const device = netDevices.find(device => device.type === DeviceType.Wifi);
        return device ? device.networks.values.find(network => network.connected) ?? null : null;
    }

    StatusIcon {
        readonly property real strength: root.wifi?.signalStrength ?? 0
        readonly property bool limited: Networking.connectivity === NetworkConnectivity.Limited || Networking.connectivity === NetworkConnectivity.Portal

        tooltip: root.tooltip
        icon: root.wired ? "lan" : root.wifi ? (strength >= 0.66 ? "wifi" : strength >= 0.33 ? "wifi_2_bar" : "wifi_1_bar") : Networking.wifiEnabled ? "signal_wifi_bad" : "wifi_off"
        color: !root.wired && !root.wifi ? Asset.Theme.muted : limited ? Asset.Theme.warning : Asset.Theme.secondary
        tooltipText: root.wired ? "Ethernet (" + root.wired.name + ")" : root.wifi ? root.wifi.name + " " + Math.round(strength * 100) + "%" : Networking.wifiEnabled ? "Disconnected" : "Wi-Fi off"
        onClicked: button => {
            if (button === Qt.RightButton)
                Networking.wifiEnabled = !Networking.wifiEnabled;
            else
                Quickshell.execDetached(["kitty", "--class", "nmtui", "nmtui"]);
        }
    }

    // Battery on laptops, the power profile elsewhere. Clicking cycles the
    // power profile; plugging in or unplugging selects one automatically.
    readonly property UPowerDevice battery: UPower.displayDevice
    readonly property var profiles: PowerProfiles.hasPerformanceProfile ? [PowerProfile.PowerSaver, PowerProfile.Balanced, PowerProfile.Performance] : [PowerProfile.PowerSaver, PowerProfile.Balanced]
    readonly property string profileName: ({
            [PowerProfile.PowerSaver]: "power saver",
            [PowerProfile.Balanced]: "balanced",
            [PowerProfile.Performance]: "performance"
        })[PowerProfiles.profile] ?? ""

    StatusIcon {
        readonly property bool hasBattery: root.battery.ready && root.battery.isLaptopBattery
        readonly property real level: root.battery.percentage
        readonly property bool charging: root.battery.state === UPowerDeviceState.Charging || root.battery.state === UPowerDeviceState.FullyCharged || root.battery.state === UPowerDeviceState.PendingCharge
        readonly property bool saving: PowerProfiles.profile === PowerProfile.PowerSaver

        tooltip: root.tooltip
        icon: {
            if (!hasBattery)
                return saving ? "eco" : PowerProfiles.profile === PowerProfile.Performance ? "speed" : "balance";
            if (charging)
                return "battery_charging_full";
            return level >= 0.95 ? "battery_full" : "battery_" + Math.min(6, Math.floor(level * 7)) + "_bar";
        }
        color: hasBattery && !charging && level < 0.15 ? Asset.Theme.danger : saving ? Asset.Theme.accentAlt : Asset.Theme.secondary
        tooltipText: {
            const profile = "Power profile: " + root.profileName;
            if (!hasBattery)
                return profile;
            let battery = "Battery " + Math.round(level * 100) + "%";
            if (root.battery.state === UPowerDeviceState.FullyCharged)
                battery += ", full";
            else if (charging && root.battery.timeToFull > 0)
                battery += ", full in " + root.duration(root.battery.timeToFull);
            else if (!charging && root.battery.timeToEmpty > 0)
                battery += ", " + root.duration(root.battery.timeToEmpty) + " left";
            return battery + "\n" + profile;
        }
        onClicked: {
            const next = (root.profiles.indexOf(PowerProfiles.profile) + 1) % root.profiles.length;
            PowerProfiles.profile = root.profiles[next];
        }
    }
}
