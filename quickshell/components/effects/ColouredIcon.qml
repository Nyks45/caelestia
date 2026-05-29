pragma ComponentBehavior: Bound

import QtQuick
import Quickshell.Widgets
import Caelestia

IconImage {
    id: root

    required property color colour

    asynchronous: true

    layer.enabled: status === Image.Ready
    layer.effect: Colouriser {
        sourceColor: analyser.dominantColour
        colorizationColor: root.colour
    }

    layer.onEnabledChanged: {
        if (layer.enabled && status === Image.Ready)
            analyser.requestUpdate();
    }

    onStatusChanged: {
        if (layer.enabled && status === Image.Ready)
            analyser.requestUpdate();
    }

    ImageAnalyser {
        id: analyser

        sourceItem: root
    }
}
