SUBDIRS =
SUBDIRS += subprojects
SUBDIRS += src
SUBDIRS += docs

top_docs = README COPYING AUTHORS TODO

EXTRA_DIST =
EXTRA_DIST += $(top_docs)
EXTRA_DIST += debian/control
EXTRA_DIST += debian/get_deps

install-data-local:
	$(MKDIR_P) $(DESTDIR)$(docdir)
	cp -r $(top_docs:%=$(srcdir)/%) $(DESTDIR)$(docdir)

uninstall-local:
	rm -f $(top_docs:%=$(DESTDIR)$(docdir)/%)
