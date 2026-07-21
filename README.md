# GPU Monitor (KDE Plasma Widget)

A lightweight KDE Plasma 6 widget (plasmoid) that graphically displays GPU
utilization in the panel. Clicking the panel graph opens a popup with a
60-second history graph, temperature, VRAM usage and power draw.

Developed and tested on Manjaro Linux with KDE Plasma 6.

See [DOCS.md](DOCS.md) for the full technical specification and architecture diagram.

## Features

- Real-time GPU utilization line graph directly in the panel
- Optional percentage label on top of the graph
- Popup with utilization history, temperature, VRAM and power draw
- Automatic GPU detection (AMD, Intel and NVIDIA via KSystemStats)
- Configurable update interval, history length and graph color
- Follows the active Plasma theme
- Translated via gettext/i18n based on the system locale (German included)

## Requirements

- KDE Plasma 6 (tested with 6.6)
- `ksystemstats` daemon (part of Plasma, usually running by default)
- KDE Frameworks 6 QML modules:
  - `org.kde.ksysguard.sensors` (package `libksysguard`)
  - `org.kde.quickcharts` (package `kquickcharts`)

On Manjaro all of these are part of the default Plasma installation.

## Installation

From the project directory:

```sh
kpackagetool6 --type Plasma/Applet --install .
```

To upgrade after making changes:

```sh
kpackagetool6 --type Plasma/Applet --upgrade .
```

To uninstall:

```sh
kpackagetool6 --type Plasma/Applet --remove com.github.sreiterer.gpumonitor
```

Then add the widget: right-click the panel → *Add Widgets…* → search for
**GPU Monitor**.

A `Makefile` is provided for convenience:

```sh
make install    # install the widget
make upgrade    # reinstall after changes
make uninstall  # remove the widget
make test       # run the test suite
make view       # preview with plasmoidviewer (if installed)

make i18n-extract  # regenerate po/template.pot and merge into po/*.po
make i18n-build    # compile po/*.po into contents/locale/
```

## Configuration

Right-click the widget → *Configure GPU Monitor…*

| Option           | Default | Description                                             |
| ---------------- | ------- | ------------------------------------------------------- |
| GPU device       | `auto`  | KSystemStats device id (`gpu0`, `gpu1`, …) or `auto`    |
| Update interval  | 1000 ms | Sensor polling interval                                 |
| History length   | 60      | Number of samples shown in the history graph            |
| Percentage label | on      | Show the current usage as text in the panel             |
| Popup details    | on      | Toggle temperature, VRAM and power rows                 |
| Graph color      | theme   | Custom graph color, defaults to the theme highlight     |

## Development

Quick preview without restarting Plasma (requires `plasma-sdk`):

```sh
plasmoidviewer -a .
```

Restart the currently installed widget after an upgrade:

```sh
systemctl --user restart plasma-plasmashell.service
```

Inspect the GPU sensors that ksystemstats exposes on your machine:

```sh
busctl --user call org.kde.ksystemstats1 /org/kde/ksystemstats1 \
    org.kde.ksystemstats1 allSensors | tr ' ' '\n' | grep gpu
```

### Project layout

```text
gpu-monitor-kde/
├── metadata.json                     # Widget metadata (Plasma 6)
├── contents/
│   ├── config/
│   │   ├── config.qml                # Config dialog categories
│   │   └── main.xml                  # Configuration schema
│   └── ui/
│       ├── main.qml                  # Entry point, sensors, GPU auto-detection
│       ├── CompactRepresentation.qml # Panel view (small live graph)
│       ├── FullRepresentation.qml    # Popup (history graph + details)
│       ├── configGeneral.qml         # Settings page
│       ├── code/
│       │   └── formatter.js          # Pure helper functions (unit-tested)
│       └── locale/                   # Compiled .mo catalogs (generated, make i18n-build)
├── po/
│   ├── template.pot                  # Message template (generated, make i18n-extract)
│   └── de.po                         # German translation
└── tests/
    ├── run-tests.sh                  # Full test suite
    └── tst_formatter.qml             # QML unit tests for formatter.js
```

### Translations (i18n)

All user-visible strings use KDE's `i18n()`/`i18np()` calls. At runtime Plasma
resolves them through the gettext domain
`plasma_applet_com.github.sreiterer.gpumonitor` against the compiled catalogs
in `contents/locale/<lang>/LC_MESSAGES/`, selected automatically by the
system locale. A German translation is included.

Typical workflow after changing or adding strings:

```sh
make i18n-extract   # update po/template.pot and merge into po/*.po
$EDITOR po/de.po    # translate new strings
make i18n-build     # compile catalogs into contents/locale/
make upgrade        # reinstall the widget
```

To add a new language, copy the template and translate it:

```sh
msginit --locale=fr --input=po/template.pot --output=po/fr.po
```

## Testing

Run the complete test suite:

```sh
./tests/run-tests.sh
```

The suite covers:

1. Package structure (all required files present)
2. `metadata.json` validation (valid JSON, required keys, Plasma 6 target)
3. `main.xml` config schema (well-formed XML)
4. QML syntax checks via `qmllint`
5. Unit tests for `formatter.js` via `qmltestrunner` (offscreen)
6. Package installability via `kpackagetool6` into a temporary package root
7. Translation checks (`.po` validity, compiled `.mo` present and current,
   runtime gettext lookup of the German catalog)

Run only the unit tests:

```sh
QT_QPA_PLATFORM=offscreen QT_LOGGING_TO_CONSOLE=1 qmltestrunner -input tests/tst_formatter.qml
```

## Troubleshooting

- **"No GPU sensors found":** Check that the daemon is running:
  `systemctl --user status plasma-ksystemstats`. For NVIDIA, the proprietary
  driver with `nvidia-smi` support is required for KSystemStats to expose
  sensors.
- **Wrong GPU selected:** Set the device id explicitly in the widget settings
  (e.g. `gpu1`). Use the `busctl` command above to list available ids.

## License

GPL-3.0-or-later
