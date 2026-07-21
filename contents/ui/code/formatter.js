/*
    Pure helper functions used by the GPU Monitor plasmoid.
    Kept free of QML dependencies so they can be unit-tested with
    qmltestrunner (see tests/tst_formatter.qml).

    SPDX-License-Identifier: GPL-3.0-or-later
*/
.pragma library

function clamp(value, min, max) {
    if (typeof value !== "number" || !isFinite(value)) {
        return min;
    }
    return Math.min(max, Math.max(min, value));
}

function formatPercent(value) {
    if (typeof value !== "number" || !isFinite(value)) {
        return "—";
    }
    return Math.round(clamp(value, 0, 100)) + "%";
}

function formatBytes(bytes) {
    if (typeof bytes !== "number" || !isFinite(bytes) || bytes < 0) {
        return "—";
    }
    var units = ["B", "KiB", "MiB", "GiB", "TiB"];
    var value = bytes;
    var unitIndex = 0;
    while (value >= 1024 && unitIndex < units.length - 1) {
        value /= 1024;
        unitIndex++;
    }
    var digits = (unitIndex === 0 || value >= 100) ? 0 : 1;
    return value.toFixed(digits) + " " + units[unitIndex];
}

function formatTemperature(celsius) {
    if (typeof celsius !== "number" || !isFinite(celsius)) {
        return "—";
    }
    return Math.round(celsius) + " °C";
}

function formatPower(watts) {
    if (typeof watts !== "number" || !isFinite(watts)) {
        return "—";
    }
    return watts.toFixed(1) + " W";
}

/*
 * Some drivers expose a temperature sensor that constantly reports 0
 * (e.g. Intel iGPUs via ksystemstats). Treat non-positive readings as
 * "not available" so the UI can hide the row instead of showing 0 °C.
 */
function sanitizeTemperature(celsius) {
    if (typeof celsius !== "number" || !isFinite(celsius) || celsius <= 0) {
        return NaN;
    }
    return celsius;
}
