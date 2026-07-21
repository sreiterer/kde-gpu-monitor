PACKAGE_ID := com.github.sreiterer.gpumonitor
TRANSLATION_DOMAIN := plasma_applet_$(PACKAGE_ID)

PO_FILES := $(wildcard po/*.po)
MO_FILES := $(patsubst po/%.po,contents/locale/%/LC_MESSAGES/$(TRANSLATION_DOMAIN).mo,$(PO_FILES))

QML_JS_SOURCES := $(shell find contents -name '*.qml' -o -name '*.js' | sort)

.PHONY: install upgrade uninstall test view i18n-extract i18n-build clean

install: i18n-build
	kpackagetool6 --type Plasma/Applet --install .

upgrade: i18n-build
	kpackagetool6 --type Plasma/Applet --upgrade .
	systemctl --user restart plasma-plasmashell.service

uninstall:
	kpackagetool6 --type Plasma/Applet --remove $(PACKAGE_ID)

test: i18n-build
	./tests/run-tests.sh

view: i18n-build
	plasmoidviewer -a .

# Regenerate po/template.pot from the QML/JS sources and merge
# new/changed strings into the existing .po files.
i18n-extract:
	xgettext --from-code=UTF-8 -C -kde -ci18n \
		-ki18n:1 -ki18nc:1c,2 -ki18np:1,2 -ki18ncp:1c,2,3 \
		--package-name="$(TRANSLATION_DOMAIN)" \
		--msgid-bugs-address="https://github.com/sreiterer/gpu-monitor-kde" \
		-o po/template.pot $(QML_JS_SOURCES)
	@for po in $(PO_FILES); do \
		echo "Merging $$po"; \
		msgmerge --update --backup=none "$$po" po/template.pot; \
	done

# Compile all .po files into the package (contents/locale/...).
i18n-build: $(MO_FILES)

contents/locale/%/LC_MESSAGES/$(TRANSLATION_DOMAIN).mo: po/%.po
	mkdir -p $(dir $@)
	msgfmt --check -o $@ $<

clean:
	rm -rf contents/locale
