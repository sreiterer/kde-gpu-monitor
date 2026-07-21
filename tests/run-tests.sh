#!/usr/bin/env bash
#
# Test suite for the GPU Monitor plasmoid.
#
# Runs, in order:
#   1. Package structure check (all required files present)
#   2. metadata.json validation (valid JSON + required keys)
#   3. contents/config/main.xml validation (well-formed XML)
#   4. QML syntax check via qmllint (errors are fatal, warnings are not)
#   5. JS unit tests via qmltestrunner (offscreen)
#   6. Package installability check via kpackagetool6 into a temp root
#   7. Translation checks (po validity, compiled .mo present and current)
#
# SPDX-License-Identifier: GPL-3.0-or-later

set -u

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$PROJECT_DIR" || exit 1

FAILURES=0

pass() { printf '\033[32m[PASS]\033[0m %s\n' "$1"; }
fail() { printf '\033[31m[FAIL]\033[0m %s\n' "$1"; FAILURES=$((FAILURES + 1)); }
skip() { printf '\033[33m[SKIP]\033[0m %s\n' "$1"; }

echo "== 1. Package structure =="
REQUIRED_FILES=(
    metadata.json
    contents/config/main.xml
    contents/config/config.qml
    contents/ui/main.qml
    contents/ui/CompactRepresentation.qml
    contents/ui/FullRepresentation.qml
    contents/ui/configGeneral.qml
    contents/ui/code/formatter.js
)
for f in "${REQUIRED_FILES[@]}"; do
    if [[ -f "$f" ]]; then
        pass "$f exists"
    else
        fail "$f is missing"
    fi
done

echo
echo "== 2. metadata.json =="
if python3 - << 'PYEOF'
import json, sys
with open("metadata.json") as f:
    data = json.load(f)
assert data.get("KPackageStructure") == "Plasma/Applet", "KPackageStructure must be Plasma/Applet"
plugin = data.get("KPlugin", {})
for key in ("Id", "Name", "Version"):
    assert plugin.get(key), f"KPlugin.{key} is missing"
assert data.get("X-Plasma-API-Minimum-Version", "").startswith("6"), "X-Plasma-API-Minimum-Version must target Plasma 6"
PYEOF
then
    pass "metadata.json is valid and contains required keys"
else
    fail "metadata.json validation failed"
fi

echo
echo "== 3. Config schema (main.xml) =="
if command -v xmllint > /dev/null; then
    if xmllint --noout contents/config/main.xml 2> /dev/null; then
        pass "main.xml is well-formed XML"
    else
        fail "main.xml is not well-formed"
    fi
else
    skip "xmllint not installed"
fi

echo
echo "== 4. QML lint (syntax errors) =="
if command -v qmllint > /dev/null; then
    while IFS= read -r qmlfile; do
        output=$(qmllint -I /usr/lib/qt6/qml "$qmlfile" 2>&1)
        if printf '%s' "$output" | grep -qE '^(Error|.*syntax error)'; then
            fail "qmllint found errors in $qmlfile"
            printf '%s\n' "$output" | grep -E '^(Error|.*syntax error)' | head -5
        else
            pass "no syntax errors in $qmlfile"
        fi
    done < <(find contents tests -name '*.qml' | sort)
else
    skip "qmllint not installed"
fi

echo
echo "== 5. Unit tests (formatter.js) =="
# Prefer the Qt 6 test runner; /usr/bin/qmltestrunner may be the Qt 5 one.
QMLTESTRUNNER=""
if [[ -x /usr/lib/qt6/bin/qmltestrunner ]]; then
    QMLTESTRUNNER=/usr/lib/qt6/bin/qmltestrunner
elif command -v qmltestrunner > /dev/null; then
    QMLTESTRUNNER=qmltestrunner
fi
if [[ -n "$QMLTESTRUNNER" ]]; then
    if QT_QPA_PLATFORM=offscreen QT_LOGGING_TO_CONSOLE=1 "$QMLTESTRUNNER" -input tests/tst_formatter.qml; then
        pass "qmltestrunner: all unit tests passed"
    else
        fail "qmltestrunner: unit tests failed"
    fi
else
    skip "qmltestrunner not installed (package: qt6-declarative)"
fi

echo
echo "== 6. Package installability (kpackagetool6) =="
if command -v kpackagetool6 > /dev/null; then
    TMPROOT=$(mktemp -d)
    if kpackagetool6 --type Plasma/Applet --install "$PROJECT_DIR" --packageroot "$TMPROOT" > /dev/null 2>&1; then
        pass "package installs cleanly into a temporary package root"
    else
        fail "kpackagetool6 could not install the package"
    fi
    rm -rf "$TMPROOT"
else
    skip "kpackagetool6 not installed"
fi

echo
echo "== 7. Translations (i18n) =="
TRANSLATION_DOMAIN="plasma_applet_com.github.sreiterer.gpumonitor"
if command -v msgfmt > /dev/null; then
    for po in po/*.po; do
        [[ -e "$po" ]] || continue
        lang=$(basename "$po" .po)
        if msgfmt --check -o /dev/null "$po" 2> /dev/null; then
            pass "$po is valid"
        else
            fail "$po contains errors (run: msgfmt --check $po)"
            continue
        fi
        mo="contents/locale/$lang/LC_MESSAGES/$TRANSLATION_DOMAIN.mo"
        if [[ ! -f "$mo" ]]; then
            fail "$mo is missing (run: make i18n-build)"
        elif [[ "$po" -nt "$mo" ]]; then
            fail "$mo is older than $po (run: make i18n-build)"
        else
            pass "$mo is present and up to date"
        fi
    done
else
    skip "msgfmt not installed (package: gettext)"
fi
if command -v gettext > /dev/null && [[ -f "contents/locale/de/LC_MESSAGES/$TRANSLATION_DOMAIN.mo" ]]; then
    translated=$(LANGUAGE=de LC_ALL=de_DE.UTF-8 TEXTDOMAINDIR="$PROJECT_DIR/contents/locale"         gettext -d "$TRANSLATION_DOMAIN" "No GPU sensors found" 2>/dev/null)
    if [[ "$translated" == "Keine GPU-Sensoren gefunden" ]]; then
        pass "German catalog resolves at runtime (gettext lookup)"
    else
        fail "German catalog lookup returned: '$translated'"
    fi
fi

echo
if [[ $FAILURES -eq 0 ]]; then
    echo "All checks passed."
    exit 0
else
    echo "$FAILURES check(s) failed."
    exit 1
fi
