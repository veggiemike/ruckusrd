dist_bin_SCRIPTS =
dist_bin_SCRIPTS += doit
dist_bin_SCRIPTS += extractenator
dist_bin_SCRIPTS += firmwarenator
dist_bin_SCRIPTS += kernel-builder
dist_bin_SCRIPTS += kernel-tar
dist_bin_SCRIPTS += microcodenator
dist_bin_SCRIPTS += ruckusrd

pkgdata_DATA =
pkgdata_DATA += linuxrc
pkgdata_DATA += ruckusrd.conf
pkgdata_DATA += initramfs.cpio.xz


install-exec-hook:
	rm -f $(DESTDIR)$(bindir)/mkinitrd
	(cd $(DESTDIR)$(bindir) && $(LN_S) ruckusrd mkinitrd)
	sed -i 's|__LIBDIR__|$(pkgdatadir)|' $(DESTDIR)$(bindir)/ruckusrd

uninstall-local:
	rm -f $(DESTDIR)$(bindir)/mkinitrd

initramfs.cpio.xz: ../Makefile ruckusrd.prep linuxrc ../subprojects/busybox.tar ../subprojects/eudev.tar ../subprojects/mdadm.tar ../subprojects/lvm2.tar ../subprojects/e2fsprogs.tar ../subprojects/squashfs-tools.tar ../subprojects/zfs.tar ../subprojects/syslinux.tar
	./ruckusrd.prep


clean-local:
	rm -f initramfs.cpio.xz
	rm -rf initramfs
