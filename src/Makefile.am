bin_SCRIPTS = ruckusrd

dist_pkgdata_DATA = linuxrc

install-exec-hook:
	$(RM) -f $(DESTDIR)$(bindir)/mkinitrd
	(cd $(DESTDIR)$(bindir) && $(LN_S) ruckusrd mkinitrd)
