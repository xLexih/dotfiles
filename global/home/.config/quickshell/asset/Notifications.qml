pragma Singleton

import Quickshell
import Quickshell.Services.Notifications
import QtQuick

// Owns the freedesktop notification server and the state the sidebar shows.
// Notifications are tracked so they survive the toast and stay in the center
// until dismissed; `unreadState` holds the ones that arrived while the center
// was closed.
Singleton {
    id: root

    readonly property var tracked: notifServer.trackedNotifications.values
    property var unreadState: []
    readonly property var unread: unreadState.filter(notification => tracked.indexOf(notification) >= 0)
    readonly property int count: tracked.length
    readonly property int unreadCount: unread.length
    readonly property bool hasUnread: unreadCount > 0

    property bool dnd: false
    property bool open: false
    property string openScreen: ""
    property var toasts: []

    function markAllRead() {
        unreadState = [];
    }

    function clearAll() {
        const items = tracked.slice();
        unreadState = [];
        toasts = [];
        // A notification can be destroyed by the daemon before the dismiss
        // round-trip; calling close() on a dead object logs an error.
        items.forEach(notification => {
            if (notification.tracked)
                notification.dismiss();
        });
    }

    function dismiss(notification) {
        unreadState = unreadState.filter(item => item !== notification);
        toasts = toasts.filter(item => item !== notification);
        if (notification.tracked)
            notification.dismiss();
    }

    function invoke(notification) {
        const actions = notification.actions ?? [];
        let action = null;
        for (let i = 0; i < actions.length; i++) {
            if (actions[i].identifier === "default") {
                action = actions[i];
                break;
            }
        }
        if (!action && actions.length > 0)
            action = actions[0];
        if (!action)
            return;
        action.invoke();
        if (!notification.resident)
            dismiss(notification);
    }

    function openOn(screenName) {
        openScreen = screenName;
        open = true;
        markAllRead();
        toasts = [];
    }

    function close() {
        open = false;
    }

    function toggleOn(screenName) {
        if (open && openScreen === screenName)
            close();
        else
            openOn(screenName);
    }

    function expireToast(notification) {
        toasts = toasts.filter(item => item !== notification);
    }

    // The freedesktop body allows a small subset of HTML. Image tags can
    // reference files, so drop them before the text is rendered.
    function safeBody(body) {
        return (body ?? "").replace(/<img\b[^>]*>/gi, "");
    }

    NotificationServer {
        id: notifServer

        keepOnReload: true
        bodySupported: true
        bodyMarkupSupported: true
        bodyHyperlinksSupported: true
        actionsSupported: true
        imageSupported: false
        inlineReplySupported: false
        persistenceSupported: true

        onNotification: notification => {
            if (notification.lastGeneration)
                return;
            if (notification.transient) {
                if (!root.open && !root.dnd)
                    root.toasts = root.toasts.concat([notification]).slice(-3);
                return;
            }
            notification.tracked = true;
            // The service exposes no timestamp; the card's relative age uses
            // the time we first saw the notification.
            notification.arrivedAt = Date.now() / 1000;
            if (root.open)
                return;
            root.unreadState = root.unreadState.concat([notification]);
            if (!root.dnd)
                root.toasts = root.toasts.concat([notification]).slice(-3);
        }
    }

    Connections {
        target: notifServer

        function onTrackedNotificationsChanged() {
            root.unreadState = root.unreadState.filter(notification => root.tracked.indexOf(notification) >= 0);
        }
    }
}
