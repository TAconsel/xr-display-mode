PREFIX ?= /usr/local
UDEVDIR ?= /usr/lib/udev/rules.d

install:
	install -Dm755 xr-display-mode $(DESTDIR)$(PREFIX)/bin/xr-display-mode
	install -Dm644 io.github.taconsel.XrDisplayMode.desktop \
		$(DESTDIR)$(PREFIX)/share/applications/io.github.taconsel.XrDisplayMode.desktop
	install -Dm644 70-xreal-hidraw.rules $(DESTDIR)$(UDEVDIR)/70-xreal-hidraw.rules

uninstall:
	rm -f $(DESTDIR)$(PREFIX)/bin/xr-display-mode \
		$(DESTDIR)$(PREFIX)/share/applications/io.github.taconsel.XrDisplayMode.desktop \
		$(DESTDIR)$(UDEVDIR)/70-xreal-hidraw.rules

.PHONY: install uninstall
