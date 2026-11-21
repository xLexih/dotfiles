pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick
import "." as Asset

// Projects registered with `project-cleanup`, refreshed every 10 s and again
// when the center opens. The center uses the countdown to show what is still
// in use and what is due.
Singleton {
    id: root

    property var projects: []
    property string error: ""
    // "latest" sorts by most recent activity first; "oldest" is the reverse.
    property string sortOrder: "latest"
    readonly property int activeCount: projects.filter(project => project.state === "in_use").length

    function refresh() {
        if (!read.running)
            read.running = true;
    }

    function openTerminal(path) {
        if (!path)
            return;
        Quickshell.execDetached(["kitty", "--directory", path]);
        // Touching the project resets its activity timestamp.
        refreshTimer.schedule(1500);
    }

    function cleanNow(path) {
        if (!path)
            return;
        Quickshell.execDetached(["project-cleanup", "now", path]);
        // The cleanup finishes in seconds; poll a few times so the row's
        // state flips without waiting for the next timer tick.
        [2000, 5000, 9000].forEach(delay => refreshTimer.schedule(delay));
    }

    function toggleSort() {
        sortOrder = sortOrder === "latest" ? "oldest" : "latest";
    }

    // Projects ordered by last activity, honoring the sort toggle. Cleaned
    // projects are done — they only reappear once they are active again.
    readonly property var sorted: {
        const list = projects.filter(project => project.state !== "cleaned");
        list.sort((a, b) => (a.last_seen - b.last_seen) * (sortOrder === "latest" ? -1 : 1));
        return list;
    }

    function formatDuration(seconds) {
        const total = Math.max(0, Math.floor(seconds));
        if (total < 60)
            return total + "s";
        const minutes = Math.floor(total / 60);
        if (minutes < 60)
            return minutes + "m";
        const hours = Math.floor(minutes / 60);
        if (hours < 24)
            return hours + "h " + (minutes % 60) + "m";
        return Math.floor(hours / 24) + "d " + (hours % 24) + "h";
    }

    Process {
        id: read

        command: ["project-cleanup", "status", "--json"]

        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const data = JSON.parse(this.text);
                    root.projects = Array.isArray(data.projects) ? data.projects : [];
                    root.error = "";
                } catch (error) {
                    root.error = "Cannot read project status";
                }
            }
        }
    }

    Timer {
        id: refreshTimer

        // Queued refresh deadlines (ms since epoch). Pops and runs the
        // earliest one, restarting itself if more remain.
        interval: 0
        repeat: false
        property var deadlines: []

        function schedule(delay) {
            deadlines.push(Date.now() + delay);
            if (!running)
                fireNext();
        }

        function fireNext() {
            if (!deadlines.length)
                return;
            deadlines.sort((a, b) => a - b);
            const wait = Math.max(0, deadlines.shift() - Date.now());
            interval = wait;
            restart();
        }

        onTriggered: {
            root.refresh();
            fireNext();
        }
    }

    Timer {
        interval: 10000
        repeat: true
        running: true
        triggeredOnStart: true
        onTriggered: root.refresh()
    }

    // The center reads the fresh list the moment it opens.
    Connections {
        target: Asset.Notifications

        function onOpenChanged() {
            if (Asset.Notifications.open)
                root.refresh();
        }
    }
}
