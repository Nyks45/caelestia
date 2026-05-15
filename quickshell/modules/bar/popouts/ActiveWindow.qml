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

    implicitWidth: Hypr.activeToplevel ? child.implicitWidth : -Tokens.padding.large * 2
    implicitHeight: child.implicitHeight

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
                source: Icons.getAppIcon(Hypr.activeToplevel?.lastIpcObject.class ?? "", "image-missing")
            }

            ColumnLayout {
                id: details
                spacing: 0
                Layout.fillWidth: true

                StyledText {
                    Layout.fillWidth: true
                    text: Hypr.activeToplevel?.title ?? ""
                    font.pointSize: Tokens.font.size.normal
                    elide: Text.ElideRight
                }

                StyledText {
                    Layout.fillWidth: true
                    text: Hypr.activeToplevel?.lastIpcObject.class ?? ""
                    color: Colours.palette.m3onSurfaceVariant
                    elide: Text.ElideRight
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

                RowLayout {
                    id: row
                    anchors.left: parent.left
                    anchors.right: parent.right
                    spacing: Tokens.spacing.normal

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
                }

                StateLayer {
                    anchors.fill: parent
                    radius: Tokens.rounding.small
                    onClicked: {
                        const ws = client.workspace;
                        if (ws?.name.startsWith("special:")) {
                            Hypr.dispatch("movetoworkspace " + Hypr.activeWsId + ",address:0x" + client.address);
                        }
                        Hypr.dispatch("focuswindow address:0x" + client.address);
                        root.popouts.hasCurrent = false;
                    }
                }
            }
        }
    }
}
