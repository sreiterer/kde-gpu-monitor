/*
    GPU Monitor Plasmoid - main entry point.

    Wires the KSystemStats sensors to the compact (panel) and full (popup)
    representations. Also performs auto-detection of the first available
    GPU device exposed by the ksystemstats daemon.

    SPDX-License-Identifier: GPL-3.0-or-later
*/
import QtQuick

import org.kde.plasma.plasmoid
import org.kde.kirigami as Kirigami
import org.kde.ksysguard.sensors as Sensors

import "code/formatter.js" as Formatter

PlasmoidItem {
    id: root

    // ---- Configuration -----------------------------------------------------

    readonly property string configuredGpuId: Plasmoid.configuration.gpuId
    readonly property int updateInterval: Math.max(200, Plasmoid.configuration.updateInterval)
    readonly property int historyLength: Math.max(10, Plasmoid.configuration.historyLength)
    readonly property color graphColor: Plasmoid.configuration.graphColor !== ""
        ? Plasmoid.configuration.graphColor
        : Kirigami.Theme.highlightColor

    // ---- GPU device resolution ---------------------------------------------

    // First GPU id found by the probe below (e.g. "gpu0", "gpu1", ...).
    property string detectedGpuId: ""

    readonly property string gpuId: configuredGpuId === "auto" ? detectedGpuId : configuredGpuId
    readonly property bool hasGpu: gpuId !== "" && usageSensor.status === Sensors.Sensor.Status.Ready

    // Probe a fixed range of candidate device ids. The ksystemstats daemon
    // numbers GPUs by DRM device, so the first present id is not always gpu0.
    Instantiator {
        model: ["gpu0", "gpu1", "gpu2", "gpu3", "gpu4", "gpu5"]

        delegate: Sensors.Sensor {
            sensorId: "gpu/" + modelData + "/name"
            enabled: root.configuredGpuId === "auto" && root.detectedGpuId === ""
            onStatusChanged: {
                if (status === Sensors.Sensor.Status.Ready && root.detectedGpuId === "") {
                    root.detectedGpuId = modelData;
                }
            }
        }
    }

    // ---- Sensors -----------------------------------------------------------

    readonly property real usageValue: hasGpu ? Formatter.clamp(usageSensor.value, 0, 100) : 0

    Sensors.Sensor {
        id: nameSensor
        sensorId: root.gpuId !== "" ? "gpu/" + root.gpuId + "/name" : ""
        enabled: root.gpuId !== ""
    }

    Sensors.Sensor {
        id: usageSensor
        sensorId: root.gpuId !== "" ? "gpu/" + root.gpuId + "/usage" : ""
        enabled: root.gpuId !== ""
        updateRateLimit: root.updateInterval
    }

    Sensors.Sensor {
        id: temperatureSensor
        sensorId: root.gpuId !== "" ? "gpu/" + root.gpuId + "/temperature" : ""
        enabled: root.gpuId !== "" && Plasmoid.configuration.showTemperature
        updateRateLimit: root.updateInterval
    }

    Sensors.Sensor {
        id: usedVramSensor
        sensorId: root.gpuId !== "" ? "gpu/" + root.gpuId + "/usedVram" : ""
        enabled: root.gpuId !== "" && Plasmoid.configuration.showVram
        updateRateLimit: root.updateInterval
    }

    Sensors.Sensor {
        id: totalVramSensor
        sensorId: root.gpuId !== "" ? "gpu/" + root.gpuId + "/totalVram" : ""
        enabled: root.gpuId !== "" && Plasmoid.configuration.showVram
    }

    Sensors.Sensor {
        id: powerSensor
        sensorId: root.gpuId !== "" ? "gpu/" + root.gpuId + "/power" : ""
        enabled: root.gpuId !== "" && Plasmoid.configuration.showPower
        updateRateLimit: root.updateInterval
    }

    Sensors.Sensor {
        id: typeSensor
        sensorId: root.gpuId !== "" ? "gpu/" + root.gpuId + "/type" : ""
        enabled: root.gpuId !== ""
    }

    // ---- Plasmoid setup ----------------------------------------------------

    switchWidth: Kirigami.Units.gridUnit * 12
    switchHeight: Kirigami.Units.gridUnit * 10

    toolTipMainText: hasGpu && nameSensor.value !== undefined
        ? String(nameSensor.value)
        : i18n("GPU Monitor")
    toolTipSubText: hasGpu
        ? i18n("Usage: %1", Formatter.formatPercent(usageValue))
        : i18n("No GPU sensors found")

    compactRepresentation: CompactRepresentation {
        usage: root.usageValue
        available: root.hasGpu
        graphColor: root.graphColor
        showLabel: Plasmoid.configuration.showLabel
        historyLength: root.historyLength
        updateInterval: root.updateInterval

        onActivated: root.expanded = !root.expanded
    }

    fullRepresentation: FullRepresentation {
        usage: root.usageValue
        available: root.hasGpu
        gpuName: root.hasGpu && nameSensor.value !== undefined ? String(nameSensor.value) : i18n("GPU")
        graphColor: root.graphColor
        historyLength: root.historyLength
        updateInterval: root.updateInterval

        showTemperature: Plasmoid.configuration.showTemperature
        showVram: Plasmoid.configuration.showVram
        showPower: Plasmoid.configuration.showPower

        temperature: temperatureSensor.status === Sensors.Sensor.Status.Ready
            ? Formatter.sanitizeTemperature(temperatureSensor.value)
            : NaN
        usedVram: usedVramSensor.status === Sensors.Sensor.Status.Ready ? usedVramSensor.value : NaN
        totalVram: totalVramSensor.status === Sensors.Sensor.Status.Ready ? totalVramSensor.value : NaN
        power: powerSensor.status === Sensors.Sensor.Status.Ready ? powerSensor.value : NaN
        gpuType: root.hasGpu && typeSensor.value !== undefined ? String(typeSensor.value) : ""
    }
}
