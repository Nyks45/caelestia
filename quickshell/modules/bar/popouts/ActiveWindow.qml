import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Widgets
import Caelestia.Config
import qs.components
import qs.components.controls
import qs.services
import qs.utils

Item {
    id: root

    required property PopoutState popouts

    property var allClients: []

    property string debugInfo: ""
    property int triggerCount: 0

    implicitWidth: Math.max(child.implicitWidth, Tokens.padding.large * 2)
    implicitHeight: Math.max(child.implicitHeight, Tokens.padding.large * 2)

    Process {
        id: hyprctlReader
        command: ["/usr/bin/python3", "-c", "import json,subprocess,sys; sys.stdout.write(subprocess.run(['hyprctl','-j','clients'],capture_output=True,text=True).stdout)"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    root.allClients = JSON.parse(text);
                    root.debugInfo = "OK: " + root.allClients.length + " clients";
                } catch (e) {
                    root.allClients = [];
                    root.debugInfo = "ERR: " + e.message + " | text=" + text.substring(0,100);
                }
            }
        }
    }

    Timer {
        interval: 1000
        running: true
        repeat: true
        onTriggered: {
            root.triggerCount++;
            root.debugInfo = "TRIGGER #" + root.triggerCount + " (allClients=" + root.allClients.length + ")";
            hyprctlReader.running = true;
        }
    }

    Component.onCompleted: {
        root.debugInfo = "INIT (allClients=" + root.allClients.length + ")";
        hyprctlReader.running = true;
    }

    Column {
        id: child

        anchors.centerIn: parent
        spacing: Tokens.spacing.normal

        Rectangle {
            id: debugRect
            visible: true
            width: 200
            height: 30
            color: "red"

            StyledText {
                anchors.centerIn: parent
                text: "wsId=" + Hypr.activeWsId
                color: "white"
                font.pointSize: 10
            }
        }

        RowLayout {
            id: detailsRow

            anchors.left: parent.left
            anchors.right: parent.right
            spacing: Tokens.spacing.normal

            IconImage {
                id: icon
                asynchronous: true
                Layout.alignment: Qt.AlignVCenter
                implicitSize: details.implicitHeight
                source: Icons.getAppIcon(Hypr.activeToplevel?.lastIpcObject.class ?? "", "desktop_windows")
            }

            ColumnLayout {
                id: details
                spacing: 0
                Layout.fillWidth: true

                StyledText {
                    Layout.fillWidth: true
                    text: Hypr.activeToplevel?.title ?? qsTr("Desktop")
                    font.pointSize: Tokens.font.size.normal
                    elide: Text.ElideRight
                }

                StyledText {
                    Layout.fillWidth: true
                    text: Hypr.activeToplevel?.lastIpcObject.class ?? ""
                    color: Colours.palette.m3onSurfaceVariant
                    elide: Text.ElideRight
                    visible: Hypr.activeToplevel != null
                }
            }

            Item {
                implicitWidth: expandIcon.implicitHeight + Tokens.padding.small * 2
                implicitHeight: expandIcon.implicitHeight + Tokens.padding.small * 2
                Layout.alignment: Qt.AlignVCenter

                StateLayer {
                    radius: Tokens.rounding.normal
                    onClicked: root.popouts.detachRequested("winfo")
                }

                MaterialIcon {
                    id: expandIcon
                    anchors.centerIn: parent
                    anchors.horizontalCenterOffset: font.pointSize * 0.05
                    text: "chevron_right"
                    font.pointSize: Tokens.font.size.large
                }
            }
        }

        ClippingWrapperRectangle {
            color: "transparent"
            radius: Tokens.rounding.small
            visible: Hypr.activeToplevel != null

            ScreencopyView {
                id: preview
                captureSource: Hypr.activeToplevel?.wayland ?? null // qmllint disable unresolved-type
                live: visible
                constraintSize.width: Tokens.sizes.bar.windowPreviewSize
                constraintSize.height: Tokens.sizes.bar.windowPreviewSize
            }
        }

        Repeater {
            model: Hypr.toplevels.values

            delegate: Item {
                required property var modelData
                readonly property var client: modelData
                readonly property bool isActive: Hypr.activeToplevel?.address === client.address

                anchors.left: parent.left
                anchors.right: parent.right
                implicitHeight: row.implicitHeight

                StateLayer {
                    anchors.fill: parent
                    radius: Tokens.rounding.small
                    z: 0
                    onClicked: {
                        const ws = client.workspace;
                        if (ws?.name === "desktop" || ws?.name.startsWith("special:")) {
                            Hypr.dispatch("movetoworkspacesilent " + Hypr.activeWsId + ",address:0x" + client.address);
                        }
                        Hypr.dispatch("focuswindow address:0x" + client.address);
                        root.popouts.hasCurrent = false;
                    }
                }

                RowLayout {
                    id: row
                    anchors.left: parent.left
                    anchors.right: parent.right
                    spacing: Tokens.spacing.normal
                    z: 1

                    MaterialIcon {
                        text: Icons.getAppCategoryIcon(client.lastIpcObject.class, "terminal")
                        color: Colours.palette.m3onSurfaceVariant
                        font.pointSize: Tokens.font.size.large
                    }

                    StyledText {
                        Layout.fillWidth: true
                        text: client.title || qsTr("Untitled")
                        elide: Text.ElideRight
                        font.weight: isActive ? 600 : 400
                    }

                    IconTextButton {
                        Layout.preferredHeight: implicitHeight
                        text: qsTr("Close")
                        icon: "close"
                        inactiveColour: Colours.palette.m3errorContainer
                        inactiveOnColour: Colours.palette.m3onErrorContainer
                        verticalPadding: Tokens.padding.smaller
                        z: 2

                        onClicked: {
                            Hypr.dispatch("killwindow address:0x" + client.address);
                            root.popouts.hasCurrent = false;
                        }
                    }
                }
            }
        }

        Repeater {
            model: ScriptModel {
                values: {
                    const currentWsId = Hypr.activeWsId;
                    const currentWsWindows = root.allClients.filter(c => c.workspace?.id === currentWsId && c.workspace?.name !== "desktop");
                    if (currentWsWindows.length > 0) return [];
                    return root.allClients;
                }
            }

            delegate: Item {
                required property var modelData
                readonly property var client: modelData
                readonly property var addr: client.address ?? ""
                readonly property var normalAddr: addr.startsWith("0x") ? addr.substring(2) : addr

                anchors.left: parent.left
                anchors.right: parent.right
                implicitHeight: row.implicitHeight

                StateLayer {
                    anchors.fill: parent
                    radius: Tokens.rounding.small
                    z: 0
                    onClicked: {
                        const ws = client.workspace;
                        if (ws?.name === "desktop" || ws?.name.startsWith("special:")) {
                            Hypr.dispatch("movetoworkspacesilent " + Hypr.activeWsId + ",address:0x" + normalAddr);
                        }
                        Hypr.dispatch("focuswindow address:0x" + normalAddr);
                        root.popouts.hasCurrent = false;
                    }
                }

                RowLayout {
                    id: row
                    anchors.left: parent.left
                    anchors.right: parent.right
                    spacing: Tokens.spacing.normal
                    z: 1

                    MaterialIcon {
                        text: Icons.getAppCategoryIcon(client.class ?? client.lastIpcObject?.class ?? "", "terminal")
                        color: Colours.palette.m3onSurfaceVariant
                        font.pointSize: Tokens.font.size.large
                    }

                    StyledText {
                        Layout.fillWidth: true
                        text: client.title || qsTr("Untitled")
                        elide: Text.ElideRight
                        opacity: 0.7
                    }

                    MaterialIcon {
                        text: "unfold_more"
                        color: Colours.palette.m3onSurfaceVariant
                        font.pointSize: Tokens.font.size.small
                        opacity: 0.5
                    }
                }
            }
        }
    }
}
