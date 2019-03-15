dist_bin_SCRIPTS =
dist_bin_SCRIPTS += extractenator
dist_bin_SCRIPTS += kernel_builder
dist_bin_SCRIPTS += kernel_installer
dist_bin_SCRIPTS += kernel_tar
dist_bin_SCRIPTS += ruckusrd

pkgdata_DATA =
pkgdata_DATA += linuxrc
pkgdata_DATA += ruckusrd.conf
pkgdata_DATA += initramfs.cpio.xz


install-exec-hook:
	rm -f $(DESTDIR)$(bindir)/mkinitrd
	(cd $(DESTDIR)$(bindir) && $(LN_S) ruckusrd mkinitrd)
	sed -i 's|__LIBDIR__|$(pkgdatadir)|' $(DESTDIR)$(bindir)/ruckusrd

initramfs.cpio.xz: ruckusrd.prep linuxrc ../subprojects/busybox.tar ../subprojects/eudev.tar ../subprojects/mdadm.tar ../subprojects/lvm2.tar ../subprojects/e2fsprogs.tar ../subprojects/squashfs-tools.tar
	./ruckusrd.prep


clean-local:
	rm -f initramfs.cpio.xz
	rm -rf initramfs
