PREFIX ?= /usr/local
DESTDIR ?=

.PHONY: install uninstall test check package
install:
	bash install.sh --system --prefix "$(PREFIX)" --destdir "$(DESTDIR)"
uninstall:
	bash install.sh --system --prefix "$(PREFIX)" --destdir "$(DESTDIR)" --uninstall
test:
	python3 -m unittest discover -s tests -v
check:
	bash scripts/check.sh
package:
	bash scripts/package.sh portable
