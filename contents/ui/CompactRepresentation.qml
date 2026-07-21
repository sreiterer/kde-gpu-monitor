/*
    Compact (panel) representation: a small live line graph with an
    optional percentage label on top.

    SPDX-License-Identifier: GPL-3.0-or-later
*/
import QtQuick
import QtQuick.Layouts

import org.kde.kirigami as Kirigami
import org.kde.plasma.components as PlasmaComponents3
import org.kde.quickcharts as Charts

import "code/formatter.js" as Formatter

Item {
    id: compactRoot

    property real usage: 0
    property bool available: false
    property color graphColor: Kirigami.Theme.highlightColor
    property bool showLabel: true
    property int historyLength: 60
    property int updateInterval: 1000

    signal activated()

    Layout.minimumWidth: Kirigami.Units.gridUnit * 2.5
    Layout.preferredWidth: Kirigami.Units.gridUnit * 3

    Charts.LineChart {
        id: chart
        anchors.fill: parent
        visible: compactRoot.available

        direction: Charts.XYChart.ZeroAtEnd
        fillOpacity: 0.35
        smooth: true

        yRange {
            from: 0
            to: 100
            automatic: false
        }

        colorSource: Charts.SingleValueSource { value: compactRoot.graphColor }

        valueSources: Charts.HistoryProxySource {
            source: Charts.SingleValueSource { value: compactRoot.usage }
            maximumHistory: compactRoot.historyLength
            interval: compactRoot.updateInterval
            fillMode: Charts.HistoryProxySource.FillFromStart
        }
    }

    PlasmaComponents3.Label {
        anchors.centerIn: parent
        visible: compactRoot.showLabel && compactRoot.available
        text: Formatter.formatPercent(compactRoot.usage)
        font.pointSize: Kirigami.Theme.smallFont.pointSize
        font.features: { "tnum": 1 }
    }

    // Fallback icon while no GPU sensor is available.
    Kirigami.Icon {
        anchors.fill: parent
        visible: !compactRoot.available
        source: "ksysguardd"
    }

    MouseArea {
        anchors.fill: parent
        onClicked: compactRoot.activated()
    }
}
