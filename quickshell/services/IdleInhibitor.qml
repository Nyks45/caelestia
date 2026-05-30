pragma Singleton

import QtQml
import Quickshell
import Quickshell.Io
import Quickshell.Wayland

Singleton {
    id: root

    property alias enabled: props.enabled
    readonly property alias enabledSince: props.enabledSince
    property real disableAt: 0

    onEnabledChanged: {
        if (enabled) {
            props.enabledSince = new Date();
        } else {
            disableAt = 0;
        }
    }

    function enableFor(minutes: int): void {
        props.enabled = true;
        disableAt = Date.now() + minutes * 60000;
        autoDisableTimer.restart();
    }

    Timer {
        id: autoDisableTimer

        interval: 30000
        repeat: true
        running: root.disableAt > 0 && root.enabled
        onTriggered: {
            if (Date.now() >= root.disableAt) {
                root.enabled = false;
            }
        }
    }

    PersistentProperties {
        id: props

        property bool enabled
        property date enabledSince

        reloadableId: "idleInhibitor"
    }

    IdleInhibitor {
        enabled: props.enabled
        window: PanelWindow {
            implicitWidth: 0
            implicitHeight: 0
            color: "transparent"
            mask: Region {}
        }
    }

    IpcHandler {
        function isEnabled(): bool {
            return props.enabled;
        }

        function toggle(): void {
            props.enabled = !props.enabled;
        }

        function enable(): void {
            props.enabled = true;
        }

        function disable(): void {
            props.enabled = false;
        }

        function enableFor(minutes: int): void {
            root.enableFor(minutes);
        }

        target: "idleInhibitor"
    }
}
