SUBDIRS =
SUBDIRS += src

EXTRA_DIST =
EXTRA_DIST += docs

install-data-local:
	$(MKDIR_P) $(DESTDIR)$(docdir)
	$(CP) -r README COPYING AUTHORS TODO docs $(DESTDIR)$(docdir)
