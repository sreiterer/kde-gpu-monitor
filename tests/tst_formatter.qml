/*
    Unit tests for contents/ui/code/formatter.js.
    Run with: QT_QPA_PLATFORM=offscreen qmltestrunner -input tests/tst_formatter.qml

    SPDX-License-Identifier: GPL-3.0-or-later
*/
import QtQuick 2.15
import QtTest 1.2

import "../contents/ui/code/formatter.js" as Formatter

TestCase {
    name: "Formatter"

    // ---- clamp -------------------------------------------------------------

    function test_clamp_withinRange() {
        compare(Formatter.clamp(50, 0, 100), 50);
    }

    function test_clamp_belowMin() {
        compare(Formatter.clamp(-10, 0, 100), 0);
    }

    function test_clamp_aboveMax() {
        compare(Formatter.clamp(150, 0, 100), 100);
    }

    function test_clamp_invalidInput() {
        compare(Formatter.clamp(NaN, 0, 100), 0);
        compare(Formatter.clamp(undefined, 0, 100), 0);
        compare(Formatter.clamp("foo", 0, 100), 0);
        compare(Formatter.clamp(Infinity, 0, 100), 0);
    }

    // ---- formatPercent -----------------------------------------------------

    function test_formatPercent_regular() {
        compare(Formatter.formatPercent(42), "42%");
        compare(Formatter.formatPercent(0), "0%");
        compare(Formatter.formatPercent(100), "100%");
    }

    function test_formatPercent_rounding() {
        compare(Formatter.formatPercent(41.4), "41%");
        compare(Formatter.formatPercent(41.5), "42%");
    }

    function test_formatPercent_clamping() {
        compare(Formatter.formatPercent(-5), "0%");
        compare(Formatter.formatPercent(120), "100%");
    }

    function test_formatPercent_invalid() {
        compare(Formatter.formatPercent(NaN), "—");
        compare(Formatter.formatPercent(undefined), "—");
    }

    // ---- formatBytes -------------------------------------------------------

    function test_formatBytes_bytes() {
        compare(Formatter.formatBytes(0), "0 B");
        compare(Formatter.formatBytes(512), "512 B");
    }

    function test_formatBytes_kibibytes() {
        compare(Formatter.formatBytes(1024), "1.0 KiB");
        compare(Formatter.formatBytes(4 * 1024), "4.0 KiB");
    }

    function test_formatBytes_mebibytes() {
        compare(Formatter.formatBytes(512 * 1024 * 1024), "512 MiB");
    }

    function test_formatBytes_gibibytes() {
        compare(Formatter.formatBytes(8 * 1024 * 1024 * 1024), "8.0 GiB");
        compare(Formatter.formatBytes(3.5 * 1024 * 1024 * 1024), "3.5 GiB");
    }

    function test_formatBytes_invalid() {
        compare(Formatter.formatBytes(-1), "—");
        compare(Formatter.formatBytes(NaN), "—");
        compare(Formatter.formatBytes(undefined), "—");
    }

    // ---- formatTemperature ---------------------------------------------------

    function test_formatTemperature_regular() {
        compare(Formatter.formatTemperature(65.4), "65 °C");
        compare(Formatter.formatTemperature(0), "0 °C");
    }

    function test_formatTemperature_invalid() {
        compare(Formatter.formatTemperature(NaN), "—");
    }

    // ---- sanitizeTemperature -------------------------------------------------

    function test_sanitizeTemperature_valid() {
        compare(Formatter.sanitizeTemperature(65.5), 65.5);
        compare(Formatter.sanitizeTemperature(1), 1);
    }

    function test_sanitizeTemperature_zeroReading() {
        // Drivers without a real GPU temperature sensor report a constant 0.
        verify(isNaN(Formatter.sanitizeTemperature(0)));
    }

    function test_sanitizeTemperature_negative() {
        verify(isNaN(Formatter.sanitizeTemperature(-5)));
    }

    function test_sanitizeTemperature_invalid() {
        verify(isNaN(Formatter.sanitizeTemperature(NaN)));
        verify(isNaN(Formatter.sanitizeTemperature(undefined)));
        verify(isNaN(Formatter.sanitizeTemperature("foo")));
    }

    // ---- formatPower ---------------------------------------------------------

    function test_formatPower_regular() {
        compare(Formatter.formatPower(15), "15.0 W");
        compare(Formatter.formatPower(7.25), "7.3 W");
    }

    function test_formatPower_invalid() {
        compare(Formatter.formatPower(NaN), "—");
    }
}
