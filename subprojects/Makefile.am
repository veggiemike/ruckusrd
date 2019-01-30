# We don't use SUBDIRS here because we don't really wont to join the
# build systems together.  I want to have very specific build scripts
# in here for each subproject.


all-local: eudev.tar busybox.tar mdadm.tar lvm2.tar

%.tar: %/FOO
	tar -C $^ -vcf $@ .

clean-local:
	rm -fv {eudev,busybox,mdadm,lvm2}.tar
	cd eudev && git clean -dfx
	cd busybox && git clean -dfx
	cd mdadm && git clean -dfx
	cd lvm2 && git clean -dfx


# FIXME: when we add --with-system-eudev to configure, we'll have to
#        conditionally replace this rule w/ one that copies files from
#        the host system.
#
# NOTE: Had to install gperf on CentOS7 for this to work
#
# NOTE: We don't run the supplied autogen.sh script because we don't
#       want to regen manpages that we're not installing
#
# FIXME: checks for BLKID on host sytem?  is this going to end up
#        conflicting w/ busybox blkid in initramfs?
#
# FIXME: LFS has you run 'udevadm hwdb --update' after install... do i
#        need to?
#
eudev/FOO:
	pushd eudev && \
	rm -rf FOO && \
	autoreconf -v --install && \
	./configure --prefix=/usr --bindir=/sbin --sbindir=/sbin \
	  --libdir=/lib --sysconfdir=/etc --libexecdir=/lib \
	  --with-rootprefix= --with-rootlibdir=/lib --disable-manpages \
	  --disable-static --disable-introspection --disable-selinux \
	  --disable-blkid && \
	make -j$(JOBCOUNT) && \
	make DESTDIR=$$PWD/FOO install && \
	popd || exit 1


# FIXME: when we add --with-system-busybox to configure, we'll have to
#        conditionally replace this rule w/ one that copies files from
#        the host system.
#
# FIXME: play with busybox.config to make things smaller.  right now,
#        we're installing everything under the sun.  also, we might
#        get smaller size if we switch to hard links.
#
#        so, not only did using hardlinks not save any space on the
#        initramfs, it caused the invocation of ruckusrd.prep to take
#        waaaaaay longer.
#
#        disabling all of Netowrking, Printing, and Mail only cut our
#        final initramfs by .1M and our build time by ~10
#        seconds... not sure that's worth it.
#
busybox/FOO:
	pushd busybox && \
	rm -rf FOO && \
	make mrproper && \
	cp ../busybox.config .config && \
	make oldconfig && \
	make -j$(JOBCOUNT_KBUILD) && \
	make CONFIG_PREFIX=$$PWD/FOO install && \
	popd || exit 1


# FIXME: when we add --with-system-mdadm to configure, we'll have to
#        conditionally replace this rule w/ one that copies files from
#        the host system.
#
# FIXME: since this installs a bunch of udev rules, maybe we shouldn't
#        allow --with-system-mdadm?
#
# NOTE: We let udev rules get installed in /usr/lib/udev, which just
#       ends up being the right place in initramfs via symlinks.
#
# NOTE: We remove manpages here because we don't want them on the
#       initramfs.
#
mdadm/FOO: eudev.tar
	pushd mdadm && \
	rm -rf FOO && \
	make -j$(JOBCOUNT) && \
	make DESTDIR=$$PWD/FOO install && \
	rm -rf FOO/usr/share && \
	popd || exit 1


# FIXME: when we add --with-system-lvm2 to configure, we'll have to
#        conditionally replace this rule w/ one that copies files from
#        the host system.
#
# NOTE: We need to make sure nothing else we're installing links
#       against the host sytem's libdevmapper... otherwise we have a
#       library conflict on the initramfs.
#
# NOTE: We remove manpages here because we don't want them on the
#       initramfs.
#
# NOTE: We disable systemd bits, but enable udev stuff and point to
#       our eudev subproject.
#
# NOTE: We disable blkid_wiping because the build system is looking at
#       the host system's libblkid... but we install busybox's version
#       of blkid in initramfs.
#
lvm2/FOO: eudev.tar
	pushd lvm2 && \
	rm -rf FOO && \
	./configure --prefix=/usr --disable-notify-dbus \
	  --disable-udev-systemd-background-jobs --disable-selinux \
	  --enable-udev_sync --enable-udev_rules \
	  --enable-udev-rule-exec-detection --disable-blkid_wiping \
	  UDEV_CFLAGS="-I$$PWD/../eudev/FOO/usr/include" \
	  UDEV_LIBS="-L$$PWD/../eudev/FOO/lib/ -ludev" \
	  PKG_CONFIG_PATH=$PWD/../eudev/FOO/lib/pkgconfig:$PWD/../eudev/FOO/usr/share/pkgconfig && \
	make -j$(JOBCOUNT) && \
	make DESTDIR=$$PWD/FOO install && \
	rm -rf FOO/usr/share && \
	popd || exit 1
