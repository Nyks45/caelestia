import QtQuick
import QtQuick.Layouts
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

    property var desktopWindows: []

    implicitWidth: Math.max(child.implicitWidth, Tokens.padding.large * 2)
    implicitHeight: Math.max(child.implicitHeight, Tokens.padding.large * 2)

    function loadDesktopWindows() {
        const xhr = new XMLHttpRequest();
        xhr.open("GET", "file:///tmp/caelestia-desktop-windows.json");
        xhr.onreadystatechange = () => {
            if (xhr.readyState === XMLHttpRequest.DONE) {
                try { root.desktopWindows = JSON.parse(xhr.responseText); }
                catch (e) { root.desktopWindows = []; }
            }
        };
        xhr.send();
    }

    Component.onCompleted: loadDesktopWindows()

    Column {
        id: child

        anchors.centerIn: parent
        spacing: Tokens.spacing.normal

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
                        if (ws?.name.startsWith("special:")) {
                            Hypr.dispatch("movetoworkspace " + Hypr.activeWsId + ",address:0x" + client.address);
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
            model: root.desktopWindows

            delegate: Item {
                required property var modelData
                readonly property var win: modelData
                anchors.left: parent.left
                anchors.right: parent.right
                implicitHeight: desktopRow.implicitHeight

                StateLayer {
                    anchors.fill: parent
                    radius: Tokens.rounding.small
                    z: 0
                    onClicked: {
                        Hypr.dispatch("movetoworkspacesilent " + Hypr.activeWsId + ",address:0x" + win.address);
                        Hypr.dispatch("focuswindow address:0x" + win.address);
                        root.popouts.hasCurrent = false;
                    }
                }

                RowLayout {
                    id: desktopRow
                    anchors.left: parent.left
                    anchors.right: parent.right
                    spacing: Tokens.spacing.normal
                    z: 1

                    MaterialIcon {
                        text: Icons.getAppCategoryIcon(win.class, "terminal")
                        color: Colours.palette.m3onSurfaceVariant
                        font.pointSize: Tokens.font.size.large
                    }

                    StyledText {
                        Layout.fillWidth: true
                        text: win.title || qsTr("Untitled")
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
