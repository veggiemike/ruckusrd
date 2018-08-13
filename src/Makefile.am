bin_SCRIPTS = ruckusrd

dist_bin_SCRIPTS =
dist_bin_SCRIPTS += kernel_builder
dist_bin_SCRIPTS += kernel_installer
dist_bin_SCRIPTS += kernel_tar
dist_bin_SCRIPTS += extractenator

pkgdata_DATA = linuxrc

install-exec-hook:
	$(RM) -f $(DESTDIR)$(bindir)/mkinitrd
	(cd $(DESTDIR)$(bindir) && $(LN_S) ruckusrd mkinitrd)
