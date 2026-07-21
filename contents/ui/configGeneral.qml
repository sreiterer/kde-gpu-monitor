/*
    "General" configuration page.

    SPDX-License-Identifier: GPL-3.0-or-later
*/
import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts

import org.kde.kirigami as Kirigami
import org.kde.kcmutils as KCM
import org.kde.kquickcontrols as KQuickControls

KCM.SimpleKCM {
    id: configRoot

    property alias cfg_updateInterval: updateIntervalSpin.value
    property alias cfg_historyLength: historyLengthSpin.value
    property alias cfg_showLabel: showLabelCheck.checked
    property alias cfg_showTemperature: showTemperatureCheck.checked
    property alias cfg_showVram: showVramCheck.checked
    property alias cfg_showPower: showPowerCheck.checked
    property string cfg_gpuId
    property string cfg_graphColor

    Kirigami.FormLayout {

        QQC2.ComboBox {
            id: gpuIdCombo
            Kirigami.FormData.label: i18n("GPU device:")
            editable: true
            model: ["auto", "gpu0", "gpu1", "gpu2", "gpu3"]
            editText: configRoot.cfg_gpuId
            onEditTextChanged: {
                if (editText !== "") {
                    configRoot.cfg_gpuId = editText;
                }
            }
        }

        QQC2.SpinBox {
            id: updateIntervalSpin
            Kirigami.FormData.label: i18n("Update interval:")
            from: 200
            to: 10000
            stepSize: 100
            textFromValue: function(value) {
                return i18n("%1 ms", value);
            }
            valueFromText: function(text) {
                return parseInt(text) || 1000;
            }
        }

        QQC2.SpinBox {
            id: historyLengthSpin
            Kirigami.FormData.label: i18n("History length:")
            from: 10
            to: 600
            stepSize: 10
            textFromValue: function(value) {
                return i18np("%1 sample", "%1 samples", value);
            }
            valueFromText: function(text) {
                return parseInt(text) || 60;
            }
        }

        Item {
            Kirigami.FormData.isSection: true
        }

        QQC2.CheckBox {
            id: showLabelCheck
            Kirigami.FormData.label: i18n("Panel:")
            text: i18n("Show percentage label")
        }

        QQC2.CheckBox {
            id: showTemperatureCheck
            Kirigami.FormData.label: i18n("Popup:")
            text: i18n("Show temperature")
        }

        QQC2.CheckBox {
            id: showVramCheck
            text: i18n("Show video memory usage")
        }

        QQC2.CheckBox {
            id: showPowerCheck
            text: i18n("Show power draw")
        }

        Item {
            Kirigami.FormData.isSection: true
        }

        RowLayout {
            Kirigami.FormData.label: i18n("Graph color:")

            QQC2.CheckBox {
                id: customColorCheck
                text: i18n("Custom:")
                checked: configRoot.cfg_graphColor !== ""
                onToggled: {
                    configRoot.cfg_graphColor = checked
                        ? colorButton.color.toString()
                        : "";
                }
            }

            KQuickControls.ColorButton {
                id: colorButton
                enabled: customColorCheck.checked
                color: configRoot.cfg_graphColor !== ""
                    ? configRoot.cfg_graphColor
                    : Kirigami.Theme.highlightColor
                onColorChanged: {
                    if (customColorCheck.checked) {
                        configRoot.cfg_graphColor = color.toString();
                    }
                }
            }
        }
    }
}
