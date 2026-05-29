import QtQuick
import QtQuick.Layouts
import Caelestia.Config
import qs.components
import qs.components.controls
import qs.services

StyledRect {
    id: root

    Layout.fillWidth: true
    implicitHeight: layout.implicitHeight + bottomRow.implicitHeight + bottomRow.anchors.topMargin + Tokens.padding.large * 2

    radius: Tokens.rounding.normal
    color: Colours.tPalette.m3surfaceContainer
    clip: true

    RowLayout {
        id: layout

        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.margins: Tokens.padding.large
        spacing: Tokens.spacing.normal

        StyledRect {
            implicitWidth: implicitHeight
            implicitHeight: icon.implicitHeight + Tokens.padding.smaller * 2

            radius: Tokens.rounding.full
            color: IdleInhibitor.enabled ? Colours.palette.m3secondary : Colours.palette.m3secondaryContainer

            MaterialIcon {
                id: icon

                anchors.centerIn: parent
                text: "coffee"
                color: IdleInhibitor.enabled ? Colours.palette.m3onSecondary : Colours.palette.m3onSecondaryContainer
                font.pointSize: Tokens.font.size.large
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 0

            StyledText {
                Layout.fillWidth: true
                text: qsTr("Keep Awake")
                font.pointSize: Tokens.font.size.normal
                elide: Text.ElideRight
            }

            StyledText {
                Layout.fillWidth: true
                text: IdleInhibitor.enabled ? qsTr("Preventing sleep mode") : qsTr("Normal power management")
                color: Colours.palette.m3onSurfaceVariant
                font.pointSize: Tokens.font.size.small
                elide: Text.ElideRight
            }
        }

        StyledSwitch {
            checked: IdleInhibitor.enabled
            onToggled: IdleInhibitor.enabled = checked
        }
    }

    // Bottom row: "Active since" chip when on, timed preset chips when off
    Item {
        id: bottomRow

        anchors.bottom: parent.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.leftMargin: Tokens.padding.large
        anchors.rightMargin: Tokens.padding.large
        anchors.topMargin: Tokens.spacing.larger
        anchors.bottomMargin: Tokens.padding.large

        implicitHeight: IdleInhibitor.enabled ? activeChip.implicitHeight : presetRow.implicitHeight

        // Active-since chip (when enabled)
        Loader {
            id: activeChip

            asynchronous: true
            opacity: IdleInhibitor.enabled ? 1 : 0
            scale: IdleInhibitor.enabled ? 1 : 0.5

            Component.onCompleted: active = Qt.binding(() => opacity > 0)

            sourceComponent: StyledRect {
                implicitWidth: activeText.implicitWidth + Tokens.padding.normal * 2
                implicitHeight: activeText.implicitHeight + Tokens.padding.small * 2

                radius: Tokens.rounding.full
                color: Colours.palette.m3primary

                StyledText {
                    id: activeText

                    anchors.centerIn: parent
                    text: IdleInhibitor.disableAt > 0
                        ? qsTr("Active · off in %1 min").arg(Math.max(1, Math.ceil((IdleInhibitor.disableAt - Date.now()) / 60000)))
                        : qsTr("Active since %1").arg(Qt.formatTime(IdleInhibitor.enabledSince, GlobalConfig.services.useTwelveHourClock ? "hh:mm a" : "hh:mm"))
                    color: Colours.palette.m3onPrimary
                    font.pointSize: Math.round(Tokens.font.size.small * 0.9)
                }
            }

            Behavior on opacity { Anim { type: Anim.StandardSmall } }
            Behavior on scale { Anim {} }
        }

        // Timed preset chips (when disabled)
        Row {
            id: presetRow

            spacing: Tokens.spacing.small
            opacity: IdleInhibitor.enabled ? 0 : 1
            scale: IdleInhibitor.enabled ? 0.5 : 1

            Repeater {
                model: [
                    { label: qsTr("15 min"), minutes: 15 },
                    { label: qsTr("30 min"), minutes: 30 },
                    { label: qsTr("1 hr"),   minutes: 60 }
                ]

                StyledRect {
                    required property var modelData

                    implicitWidth: chipText.implicitWidth + Tokens.padding.normal * 2
                    implicitHeight: chipText.implicitHeight + Tokens.padding.small * 2
                    radius: Tokens.rounding.full
                    color: Colours.palette.m3secondaryContainer

                    StyledText {
                        id: chipText
                        anchors.centerIn: parent
                        text: modelData.label
                        color: Colours.palette.m3onSecondaryContainer
                        font.pointSize: Math.round(Tokens.font.size.small * 0.9)
                    }

                    StateLayer {
                        radius: parent.radius
                        onClicked: IdleInhibitor.enableFor(modelData.minutes)
                    }
                }
            }

            Behavior on opacity { Anim { type: Anim.StandardSmall } }
            Behavior on scale { Anim {} }
        }

        // No Behavior here — card's own implicitHeight Behavior handles the smooth resize.
        // A second Behavior on the same chain causes competing animations (jitter).
    }

    Behavior on implicitHeight {
        Anim {
            type: Anim.DefaultSpatial
        }
    }
}
