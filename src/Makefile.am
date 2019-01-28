dist_bin_SCRIPTS =
dist_bin_SCRIPTS += extractenator
dist_bin_SCRIPTS += kernel_builder
dist_bin_SCRIPTS += kernel_installer
dist_bin_SCRIPTS += kernel_tar
dist_bin_SCRIPTS += ruckusrd

pkgdata_DATA = linuxrc

install-exec-hook:
	$(RM) -f $(DESTDIR)$(bindir)/mkinitrd
	(cd $(DESTDIR)$(bindir) && $(LN_S) ruckusrd mkinitrd)
