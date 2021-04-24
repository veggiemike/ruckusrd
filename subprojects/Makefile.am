# We don't use SUBDIRS here because we don't really wont to join the
# build systems together.  I want to have very specific build scripts
# in here for each subproject.


all-local: eudev.tar busybox.tar mdadm.tar lvm2.tar e2fsprogs.tar squashfs-tools.tar zfs.tar syslinux.tar dropbear.tar rsync.tar efibootmgr.tar

%.tar: %/FOO
	tar -C $^ -vcf $@ .

clean-local:
	rm -fv {eudev,busybox,mdadm,lvm2,e2fsprogs,squashfs-tools,zfs,syslinux,dropbear,rsync,efibootmgr}.tar
	cd eudev && git clean -dfx && git stash
	cd busybox && git clean -dfx && git stash
	cd mdadm && git clean -dfx && git stash
	cd lvm2 && git clean -dfx && git stash
	cd e2fsprogs && git clean -dfx && git stash
	cd squashfs-tools && git clean -dfx && git stash
	cd zfs && git clean -dfx && git stash
	rm -rf syslinux-6.03
	cd dropbear && git clean -dfx && git stash
	cd rsync && git clean -dfx && git stash
	cd efibootmgr && git clean -dfx && git stash


# FIXME: when we add --with-system-eudev to configure, we'll have to
#        conditionally replace this rule w/ one that copies files from
#        the host system.
#
# NOTE: Had to install gperf on CentOS7 for this to work
#
# NOTE: We don't run the supplied autogen.sh script because we don't
#       want to regen manpages that we're not installing
#
# FIXME: compilation failure on CentOS7 with eudev-3.2.5...
#        BLKID_SUBLKS_BADCSUM undeclared.  Offending code was
#        introduced prior to v3.0 by
#        c93ec252df0a0a0bb499031f92b240063e17fc12 "blkid: Warn when
#        rejecting a superblock with a bad csum".  The commit mentions
#        that the libblkid requirement should get bumped from 2.20 to
#        2.24 and that util-linux 2.25 is already required since
#        fdbbad981cc5da8bb4ed7e9b6646e7a114745ec5.
#
#        configure.ac still checks for 2.20 though.
#
#        CentOS7 has libblkid-2.23.2 and util-linux-2.23.2
#
#        the 2nd commit mentioned doesn't apear anywhere in the eudev
#        history, i suspect it was a general systemd commit being
#        referenced...?  the rest of eudev 3.2.5 compiles fine.
#
#        for now, i'm reverting the commit so we can continue to use
#        3.2.5 (upstream 220)... although i could downgrade to v2.1.1
#        (upstream 217)...  lvm2 does a bunch of udev and systemd
#        pkg-config checking, but all the minimum versions it looks
#        for are much older than 217.
#
#        so that works, but i don't think i really need to go that
#        far.  if i set BLKID_SUBLKS_BADCSUM=0, the code in question
#        will just never happen...
#
#        or even better, i'll conditionally set it to 0 if not
#        defined.  :-)
#
eudev/FOO:
	pushd eudev && \
	rm -rf FOO && \
	sed -i '/^#include <blkid\/blkid.h>/a #ifndef BLKID_SUBLKS_BADCSUM\n#define BLKID_SUBLKS_BADCSUM 0\n#endif' src/udev/udev-builtin-blkid.c && \
	autoreconf -v --install && \
	./configure --prefix=/usr --bindir=/sbin --sbindir=/sbin \
	  --libdir=/lib --sysconfdir=/etc --libexecdir=/lib \
	  --with-rootprefix= --with-rootlibdir=/lib --disable-manpages \
	  --disable-static --disable-introspection --disable-selinux \
	  --enable-blkid --enable-kmod && \
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
# NOTE: We remove a couple bb symlinks here because some of our other
#       subprojects provide them.  We could stop compiling them by
#       tweaking .config, but this seems easier (and more flexible)
#       for now.
#
busybox/FOO:
	pushd busybox && \
	rm -rf FOO && \
	make mrproper && \
	cp ../busybox.config .config && \
	make oldconfig && \
	make -j$(JOBCOUNT_KBUILD) && \
	make CONFIG_PREFIX=$$PWD/FOO install && \
	rm -f FOO/bin/{lsattr,chattr} && \
	rm -f FOO/sbin/{fsck,tune2fs,mke2fs,mkfs.ext2} && \
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
	sed -i 's|-Werror||g' Makefile && \
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
lvm2/FOO: eudev.tar
	pushd lvm2 && \
	rm -rf FOO && \
	./configure --prefix=/usr --disable-notify-dbus \
	  --disable-udev-systemd-background-jobs --disable-selinux \
	  --enable-udev_sync --enable-udev_rules \
	  --enable-udev-rule-exec-detection \
	  UDEV_CFLAGS="-I$$PWD/../eudev/FOO/usr/include" \
	  UDEV_LIBS="-L$$PWD/../eudev/FOO/lib/ -ludev" \
	  CPPFLAGS="-I$$PWD/../eudev/FOO/usr/include" \
	  LDFLAGS="-L$$PWD/../eudev/FOO/lib/" \
	  PKG_CONFIG_PATH=$PWD/../eudev/FOO/lib/pkgconfig:$PWD/../eudev/FOO/usr/share/pkgconfig && \
	make -j$(JOBCOUNT) && \
	make DESTDIR=$$PWD/FOO install && \
	rm -rf FOO/usr/share && \
	popd || exit 1


# FIXME: when we add --with-system-e2fsprogs to configure, we'll have to
#        conditionally replace this rule w/ one that copies files from
#        the host system.
#
# NOTE: We remove manpages here because we don't want them on the
#       initramfs.
#
# NOTE: A bunch of programs installed here overlap w/ busybox (e.g.,
#       chattr, lsatter, tune2fs, fsck).  For now, we'll use the
#       full-featured variants because I think we care more about that
#       than initrd size.  In order to keep our build scripts from
#       borking, we remove the unneeded bb symlinks in the busybox
#       build script.
#
e2fsprogs/FOO:
	pushd e2fsprogs && \
	rm -rf FOO && \
	./configure --prefix=/usr && \
	make -j$(JOBCOUNT) && \
	make DESTDIR=$$PWD/FOO install && \
	rm -rf FOO/usr/share && \
	popd || exit 1


# FIXME: when we add --with-system-squashfs-tools to configure, we'll
#        have to conditionally replace this rule w/ one that copies
#        files from the host system.
#
squashfs-tools/FOO:
	pushd squashfs-tools && \
	rm -rf FOO && \
	sed -i \
	    -e 's|^#XZ_SUPPORT|XZ_SUPPORT|' \
	    -e 's|^#LZO_SUPPORT|LZO_SUPPORT|' \
	    -e 's|^#LZ4_SUPPORT|LZ4_SUPPORT|' \
	    -e 's|^#LZMA_XZ_SUPPORT|LZMA_XZ_SUPPORT|' \
	    -e 's|^#ZSTD_SUPPORT|ZSTD_SUPPORT|' \
	    squashfs-tools/Makefile && \
	make -j$(JOBCOUNT) -C squashfs-tools && \
	make -C squashfs-tools INSTALL_DIR=$$PWD/FOO/usr/sbin install && \
	popd || exit 1


# FIXME: when we add --with-system-zfs to configure, we'll have to
#        conditionally replace this rule w/ one that copies files from
#        the host system.
#
zfs/FOO:
	pushd zfs && \
	rm -rf FOO && \
	./autogen.sh && \
	./configure --prefix=/usr --sbindir=/sbin --sysconfdir=/etc \
	  --localstatedir=/var --with-systemdunitdir=/lib/systemd/system \
	  --with-systemdpresetdir=/lib/systemd/system-preset \
	  --with-systemdgeneratordir=/lib/systemd/system-generator \
	  --enable-linux-builtin && \
	make -j$(JOBCOUNT) && \
	make DESTDIR=$$PWD/FOO install && \
	rm -rf $$PWD/FOO/usr/include && \
	rm -rf $$PWD/FOO/usr/share/zfs/zfs-tests && \
	popd || exit 1


syslinux-6.03.tar.xz:
	wget https://mirrors.edge.kernel.org/pub/linux/utils/boot/syslinux/$@

syslinux/FOO: syslinux-6.03.tar.xz
	tar xf $< && \
	mv syslinux-6.03 syslinux && \
	pushd syslinux && \
	make install INSTALLROOT=$$PWD/FOO && \
	popd || exit 1


dropbear/FOO:
	pushd dropbear && \
	rm -rf FOO && \
	sed -i 's|ln -s $$(bindir)/|ln -s |' Makefile.in && \
	autoreconf && \
	./configure --prefix=/usr --bindir=/bin --sbindir=/bin && \
	make clean && \
	make -j$(JOBCOUNT) \
          PROGRAMS="dropbear dbclient dropbearkey dropbearconvert scp" \
          MULTI=1 && \
	make \
          PROGRAMS="dropbear dbclient dropbearkey dropbearconvert scp" \
          MULTI=1 \
          DESTDIR=$$PWD/FOO install && \
	ln -s dbclient FOO/bin/ssh && \
	popd || exit 1


rsync/FOO:
	pushd rsync && \
	rm -rf FOO && \
	./prepare-source && \
	./configure --prefix=/usr --bindir=/bin --disable-md2man \
          --disable-xxhash --disable-zstd --disable-openssl --disable-debug && \
        make -j$(JOBCOUNT) && make DESTDIR=$$PWD/FOO install && \
	popd || exit 1


efibootmgr/FOO:
	pushd efibootmgr && \
	rm -rf FOO && \
	make EFIDIR=ruckus && \
	make EFIDIR=ruckus DESTDIR=$$PWD/FOO install && \
	popd || exit 1
