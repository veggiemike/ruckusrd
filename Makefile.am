SUBDIRS =
SUBDIRS += subprojects
SUBDIRS += src
SUBDIRS += docs

top_docs = README COPYING AUTHORS TODO
deb_examples = debian/control debian/get_deps

EXTRA_DIST =
EXTRA_DIST += $(top_docs)
EXTRA_DIST += $(deb_examples)

install-data-local:
	$(MKDIR_P) $(DESTDIR)$(docdir)/debian
	cp -r $(top_docs:%=$(srcdir)/%) $(DESTDIR)$(docdir)
	cp -r $(deb_examples:%=$(srcdir)/%) $(DESTDIR)$(docdir)/debian

uninstall-local:
	rm -f $(top_docs:%=$(DESTDIR)$(docdir)/%)
	rm -f $(deb_examples:%=$(DESTDIR)$(docdir)/%)
