dist_bin_SCRIPTS =
dist_bin_SCRIPTS += extractenator
dist_bin_SCRIPTS += kernel_builder
dist_bin_SCRIPTS += kernel_installer
dist_bin_SCRIPTS += kernel_tar
dist_bin_SCRIPTS += ruckusrd

pkgdata_DATA =
pkgdata_DATA += linuxrc
pkgdata_DATA += ruckusrd.conf
pkgdata_DATA += lower.sqsh


install-exec-hook:
	rm -f $(DESTDIR)$(bindir)/mkinitrd
	(cd $(DESTDIR)$(bindir) && $(LN_S) ruckusrd mkinitrd)
	sed -i 's|__LIBDIR__|$(pkgdatadir)|' $(DESTDIR)$(bindir)/ruckusrd

lower.sqsh:
	./ruckusrd.prep


clean-local:
	rm -f lower.sqsh
	rm -rf initramfs
