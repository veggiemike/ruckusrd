# We don't use SUBDIRS here because we don't really wont to join the
# build systems together.  I want to have very specific build scripts
# in here for each subproject.


all: eudev.tar busybox.tar mdadm.tar lvm2.tar

%.tar: %/FOO
	tar -C $^ -vcf $@ .

clean:
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
# FIXME: this installs udev rules in usr/lib/udev...  double check
#        that path once i've added eudev subproject.
#
# FIXME: if this is mucking w/ udev rules, maybe we shouldn't allow
#        --with-system-mdadm?
#
# NOTE: We remove manpages here because we don't want them on the
#       initramfs.
#
mdadm/FOO:
	pushd mdadm && \
	make -j$(JOBCOUNT) && \
	make DESTDIR=$$PWD/FOO install && \
	rm -rf FOO/usr/share && \
	popd || exit 1


# FIXME: when we add --with-system-lvm2 to configure, we'll have to
#        conditionally replace this rule w/ one that copies files from
#        the host system.
#
# FIXME: this installs /etc/lvm which might conflict w/ what's
#        currently in our linuxrc script
#
# FIXME: make sure nothing else we're installing links against the
#        host sytem's libdevmapper... otherwise we have a library
#        conflict on the initramfs.
#
# NOTE: We remove manpages and header files here because we don't want
#       them on the initramfs.
#
# FIXME: shoot, this is linking against host sytem's libudev... which
#        is going to cause library conflicts in initramfs once we add
#        eudev.  --disable-udev_sync and --disable-udev-rules?
#        built-in blkid?  both check libudev via pkgconfig...
#
#        don't use systemd: --disable-notify-dbus
#        --disable-udev-systemd-background-jobs
#
#        hmm... i can't seem to keep this from linking against udev,
#        even w/ all that stuff disabled...  and I can't see where
#        it's getting linked in lvm's build systems... or included
#        libs... blarg.  maybe set UDEV_LIBS, UDEV_CFLAGS, etc during
#        build?
#
lvm2/FOO:
	pushd lvm2 && \
	./configure --prefix=/usr && \
	make -j$(JOBCOUNT) && \
	make DESTDIR=$$PWD/FOO install && \
	rm -rf FOO/usr/{include,share} && \
	popd || exit 1
