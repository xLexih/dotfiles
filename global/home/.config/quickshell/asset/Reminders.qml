pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick

// Small persistent checklist shown in the notification center. It lives in
// Quickshell's state directory, so it survives rebuilds and reloads.
Singleton {
    id: root

    property var items: []
    readonly property int pending: items.filter(item => !item.done).length

    function add(text) {
        const value = text.trim();
        if (!value)
            return;
        items = items.concat([{
            id: Date.now().toString(36) + Math.random().toString(36).slice(2, 7),
            text: value,
            done: false,
            createdAt: Date.now()
        }]);
        save();
    }

    function toggle(id) {
        items = items.map(item => item.id === id ? Object.assign({}, item, {done: !item.done}) : item);
        save();
    }

    function remove(id) {
        items = items.filter(item => item.id !== id);
        save();
    }

    function save() {
        adapter.items = items;
        file.writeAdapter();
    }

    FileView {
        id: file

        path: Quickshell.statePath("reminders.json")
        preload: true
        atomicWrites: true

        onLoaded: root.items = Array.isArray(adapter.items) ? adapter.items : []

        JsonAdapter {
            id: adapter
            property var items: []
        }
    }
}
