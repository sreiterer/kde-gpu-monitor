/*
    Full (popup) representation: a large history graph plus detail rows
    for temperature, VRAM and power draw.

    SPDX-License-Identifier: GPL-3.0-or-later
*/
import QtQuick
import QtQuick.Layouts

import org.kde.kirigami as Kirigami
import org.kde.plasma.components as PlasmaComponents3
import org.kde.plasma.extras as PlasmaExtras
import org.kde.quickcharts as Charts

import "code/formatter.js" as Formatter

PlasmaExtras.Representation {
    id: fullRoot

    property real usage: 0
    property bool available: false
    property string gpuName: ""
    property color graphColor: Kirigami.Theme.highlightColor
    property int historyLength: 60
    property int updateInterval: 1000

    property bool showTemperature: true
    property bool showVram: true
    property bool showPower: true

    property real temperature: NaN
    property real usedVram: NaN
    property real totalVram: NaN
    property real power: NaN

    Layout.preferredWidth: Kirigami.Units.gridUnit * 20
    Layout.preferredHeight: Kirigami.Units.gridUnit * 15
    Layout.minimumWidth: Kirigami.Units.gridUnit * 14
    Layout.minimumHeight: Kirigami.Units.gridUnit * 10

    collapseMarginsHint: true

    // Shown when no GPU sensors could be found at all.
    PlasmaExtras.PlaceholderMessage {
        anchors.centerIn: parent
        width: parent.width - Kirigami.Units.gridUnit * 4
        visible: !fullRoot.available
        iconName: "dialog-warning"
        text: i18n("No GPU sensors found")
        explanation: i18n("Make sure the ksystemstats service is running and your GPU driver exposes usage statistics.")
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: Kirigami.Units.largeSpacing
        spacing: Kirigami.Units.largeSpacing
        visible: fullRoot.available

        RowLayout {
            Layout.fillWidth: true

            Kirigami.Heading {
                Layout.fillWidth: true
                level: 3
                text: fullRoot.gpuName
                elide: Text.ElideRight
            }

            Kirigami.Heading {
                level: 3
                text: Formatter.formatPercent(fullRoot.usage)
                font.features: { "tnum": 1 }
            }
        }

        // History graph of the last historyLength samples.
        Rectangle {
            Layout.fillWidth: true
            Layout.fillHeight: true
            color: "transparent"
            border.color: Kirigami.Theme.disabledTextColor
            border.width: 1
            radius: Kirigami.Units.cornerRadius

            Charts.LineChart {
                anchors.fill: parent
                anchors.margins: 1

                direction: Charts.XYChart.ZeroAtEnd
                fillOpacity: 0.25
                smooth: true

                yRange {
                    from: 0
                    to: 100
                    automatic: false
                }

                colorSource: Charts.SingleValueSource { value: fullRoot.graphColor }

                valueSources: Charts.HistoryProxySource {
                    source: Charts.SingleValueSource { value: fullRoot.usage }
                    maximumHistory: fullRoot.historyLength
                    interval: fullRoot.updateInterval
                    fillMode: Charts.HistoryProxySource.FillFromStart
                }
            }
        }

        Kirigami.FormLayout {
            Layout.fillWidth: true

            PlasmaComponents3.Label {
                Kirigami.FormData.label: i18n("Temperature:")
                visible: fullRoot.showTemperature && !isNaN(fullRoot.temperature)
                text: Formatter.formatTemperature(fullRoot.temperature)
            }

            PlasmaComponents3.Label {
                Kirigami.FormData.label: i18n("Video memory:")
                visible: fullRoot.showVram && !isNaN(fullRoot.usedVram)
                text: isNaN(fullRoot.totalVram) || fullRoot.totalVram <= 0
                    ? Formatter.formatBytes(fullRoot.usedVram)
                    : i18n("%1 of %2", Formatter.formatBytes(fullRoot.usedVram), Formatter.formatBytes(fullRoot.totalVram))
            }

            PlasmaComponents3.Label {
                Kirigami.FormData.label: i18n("Power:")
                visible: fullRoot.showPower && !isNaN(fullRoot.power)
                text: Formatter.formatPower(fullRoot.power)
            }
        }
    }
}
