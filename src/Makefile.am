dist_bin_SCRIPTS = ruckusrd

dist_pkgdata_DATA = linuxrc

# FIXME: need to make sure path substitutions happen.  might only need it for ruckusrd.

# FIXME: i want to also install a symlink mkinintrd->ruckusrd



#ALL_FILES= $(dist_bin_SCRIPTS)
#ALL_FILES+= $(dist_pkglibexec_SCRIPTS)
#
## Sed in paths to directories in the scripts.
#install-data-hook:
#	for x in $(dist_bin_SCRIPTS); do \
#		sed -i 's|__CONFIG_DIR__|$(localstatedir)/$(PACKAGE)/config|' $(DESTDIR)$(bindir)/$$x; \
#		sed -i 's|__DEV__||' $(DESTDIR)$(bindir)/$$x; \
#		sed -i 's|__SCRIPT_DIR__|$(pkglibexecdir)|' $(DESTDIR)$(bindir)/$$x; \
#		sed -i 's|__LOCALSTATEDIR__|$(localstatedir)/$(PACKAGE)|' $(DESTDIR)$(bindir)/$$x; \
#	done; \
#	for x in $(dist_pkglibexec_SCRIPTS); do \
#		sed -i 's|__CONFIG_DIR__|$(localstatedir)/$(PACKAGE)/config|' $(DESTDIR)$(pkglibexecdir)/$$x; \
#		sed -i 's|__DEV__||' $(DESTDIR)$(pkglibexecdir)/$$x; \
#		sed -i 's|__SCRIPT_DIR__|$(pkglibexecdir)|' $(DESTDIR)$(pkglibexecdir)/$$x; \
#		sed -i 's|__LOCALSTATEDIR__|$(localstatedir)/$(PACKAGE)|' $(DESTDIR)$(pkglibexecdir)/$$x; \
#	done
