pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Caelestia.Config
import qs.components
import qs.modules.sidebar as Sidebar
import qs.modules.bar.popouts as BarPopouts

Item {
    id: root

    required property DrawerVisibilities visibilities
    required property Sidebar.Wrapper sidebar
    required property BarPopouts.Wrapper popouts
    property real horizontalStretch
    property matrix4x4 deformMatrix

    readonly property PersistentProperties props: PersistentProperties {
        property bool recordingListExpanded: false
        property string recordingConfirmDelete
        property string recordingMode

        reloadableId: "utilities"
    }
    readonly property bool shouldBeActive: visibilities.utilities && Config.utilities.enabled && !(visibilities.session && Config.session.enabled)
    property real offsetScale: shouldBeActive ? 0 : 1
    property real sidebarLerp

    // Cached slide distance — stable throughout animation.
    // Seeded to 200 as a plausible first-open estimate.
    property real _slideFrom: 200
    // Keep content alive after first open so re-opens are instant and smooth.
    property bool _everOpened: false

    visible: offsetScale < 1
    implicitHeight: content.implicitHeight + content.anchors.margins * 2
    implicitWidth: sidebar.width * (1 - sidebar.offsetScale) * horizontalStretch * sidebarLerp + Tokens.sizes.utilities.width * (1 - sidebarLerp)
    opacity: 1 - offsetScale

    // GPU transform — slides the panel down when hiding without touching layout.
    // Replaces anchors.bottomMargin which was a layout property that forced full
    // sibling re-measurement on every animation frame.
    transform: Translate { y: root._slideFrom * root.offsetScale }

    // Capture the real height once the panel is fully open.
    onImplicitHeightChanged: {
        if (implicitHeight > 0 && shouldBeActive)
            _slideFrom = implicitHeight + 5;
    }

    onShouldBeActiveChanged: {
        if (shouldBeActive)
            _everOpened = true;
    }

    states: State {
        name: "attachedToSidebar"
        when: root.visibilities.sidebar

        PropertyChanges {
            root.sidebarLerp: 1
        }
    }

    transitions: [
        Transition {
            from: ""

            Anim {
                property: "sidebarLerp"
                duration: Tokens.anim.durations.expressiveDefaultSpatial / 2
                easing: Tokens.anim.standardAccel
            }
        },
        Transition {
            to: ""

            Anim {
                property: "sidebarLerp"
                duration: Tokens.anim.durations.expressiveDefaultSpatial / 2
                easing: Tokens.anim.standardDecel
            }
        }
    ]

    Behavior on offsetScale {
        Anim {
            type: Anim.DefaultSpatial
        }
    }

    Loader {
        id: content

        anchors.top: parent.top
        anchors.left: parent.left
        anchors.margins: Tokens.padding.large

        asynchronous: true
        active: root.shouldBeActive || root.visible || root._everOpened

        sourceComponent: Content {
            implicitWidth: root.implicitWidth - content.anchors.margins * 2
            props: root.props
            visibilities: root.visibilities
            popouts: root.popouts
            deformMatrix: root.deformMatrix
        }
    }
}
