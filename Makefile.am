SUBDIRS =
SUBDIRS += src
SUBDIRS += docs

top_docs = README COPYING AUTHORS TODO

EXTRA_DIST =
EXTRA_DIST += $(top_docs)

install-data-local:
	$(MKDIR_P) $(DESTDIR)$(docdir)
	$(CP) -r $(top_docs:%=$(srcdir)/%) $(DESTDIR)$(docdir)

uninstall-local:
	$(RM) -f $(top_docs:%=$(DESTDIR)$(docdir)/%)
