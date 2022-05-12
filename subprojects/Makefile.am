# We don't use SUBDIRS here because we don't really wont to join the
# build systems together.  I want to have very specific build scripts
# in here for each subproject.


all-local: util-linux.tar eudev.tar busybox.tar mdadm.tar lvm2.tar e2fsprogs.tar squashfs-tools.tar zfs.tar syslinux.tar dropbear.tar rsync.tar efibootmgr.tar
all-local: fw.sqsh ucode.img

%.tar: %/FOO
	tar -C $^ -vcf $@ .

clean-local:
	rm -fv {util-linux,eudev,busybox,mdadm,lvm2,e2fsprogs,squashfs-tools,zfs,syslinux,dropbear,rsync,efibootmgr}.tar
	rm -fv fw.sqsh ucode.img
	rm -rf .build*
	cd util-linux && git clean -dfx && git stash
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


# NOTE: This is added because the busybox fdisk applet doesn't work
#       for GPT and that kinda sucks.  The util-linux version requires
#       libuuid, so that's enabled too... and then we enable libblkid
#       because it's need alongside libuuid for a bunch of other
#       things wer're building and using one from host system and one
#       from our ruckusrd subprojects seems like a bad idea.  And at
#       that point, why not add the real blkid too.
#
# NOTE: Make sure nothing links against the host system's libblkid or
#       libuuid, otherwise we'll end up with library conflicts on the
#       initramfs.
#
# FIXME: Might want to consider mount, libmount, losetup, fsck
#
util-linux/FOO:
	pushd util-linux && \
	rm -rf FOO && \
	./autogen.sh && \
	./configure --prefix=/usr --libdir=/usr/lib --sysconfdir=/etc \
	  --localstatedir=/var --bindir=/bin --sbindir=/sbin \
          --disable-manpages --disable-static \
	  --disable-all-programs \
	  --enable-fdisks --enable-libfdisk --enable-libuuid \
	  --enable-libsmartcols --enable-libblkid --enable-blkid \
	  --disable-asciidoc --without-python --without-systemd \
	  --without-btrfs --disable-bash-completion && \
	make -j$(JOBCOUNT) && \
	make DESTDIR=$$PWD/FOO install && \
	rm -rf $$PWD/FOO/usr/share && \
	rmdir $$PWD/FOO/bin $$PWD/FOO/usr/{bin,sbin} && \
	popd || exit 1


# NOTE: We don't run the supplied autogen.sh script because we don't
#       want to regen manpages that we're not installing
#
# NOTE: This compiles and links against our freshly built libblkid
#       (util-linux).
#
# NOTE: Make sure nothing links against the host system's libudev,
#       otherwise we'll end up with library conflicts on the
#       initramfs.
#
eudev/FOO: util-linux.tar
	pushd eudev && \
	rm -rf FOO && \
	autoreconf -f -i -s && \
	./configure --prefix=/usr --libdir=/usr/lib --sysconfdir=/etc \
	  --localstatedir=/var --bindir=/bin --sbindir=/sbin \
          --disable-static --disable-manpages \
	  --with-rootprefix= \
	  --disable-introspection --disable-selinux \
	  --enable-blkid --enable-kmod \
	  BLKID_CFLAGS="-I$$PWD/../util-linux/FOO/usr/include" \
	  BLKID_LIBS="-L$$PWD/../util-linux/FOO/usr/lib/ -lblkid" && \
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
	rm -f FOO/sbin/{fdisk,sfdisk,cfdisk,blkid} && \
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
# NOTE: This compiles and links against our freshly built libblkid
#       (util-linux) and libudev (eudev).
#
lvm2/FOO: eudev.tar
	pushd lvm2 && \
	rm -rf FOO && \
	./configure --prefix=/usr --libdir=/usr/lib --sysconfdir=/etc \
	  --localstatedir=/var --bindir=/bin --sbindir=/sbin \
          --disable-static --disable-manpages \
	  --disable-notify-dbus --enable-pkgconfig \
	  --disable-udev-systemd-background-jobs --disable-selinux \
	  --enable-udev_sync --enable-udev_rules \
	  --enable-udev-rule-exec-detection \
	  BLKID_CFLAGS="-I$$PWD/../util-linux/FOO/usr/include -I$$PWD/../util-linux/FOO/usr/include/blkid" \
	  BLKID_LIBS="-L$$PWD/../util-linux/FOO/usr/lib/ -lblkid" \
	  UDEV_CFLAGS="-I$$PWD/../eudev/FOO/usr/include" \
	  UDEV_LIBS="-L$$PWD/../eudev/FOO/usr/lib/ -ludev" && \
	make -j$(JOBCOUNT) && \
	make DESTDIR=$$PWD/FOO install && \
	rm -rf FOO/usr/share &&  \
	popd || exit 1


# NOTE: A bunch of programs installed here overlap w/ busybox (e.g.,
#       chattr, lsatter, tune2fs, fsck).  For now, we'll use the
#       full-featured variants because I think we care more about that
#       than initrd size.  In order to keep our build scripts from
#       borking, we remove the unneeded bb symlinks in the busybox
#       build script.
#
# NOTE: It's not as pretty as I'd like, but we are compiling and
#       linking against our freshly built libblkid and libuuid
#       (util-linux).  The configure script doesn't apear to use
#       pkg-config 100% of the time, so I've added the appropriate
#       flags to CFLAGS and LDDFLAGS so all the lib check tests use
#       the right libs.  Also, it doesn't look like this needs libudev
#       at all... the pkg-config checks must be for determining paths
#       for udev helpers.
#
e2fsprogs/FOO: util-linux.tar eudev.tar
	pushd e2fsprogs && \
	rm -rf FOO && \
	./configure --prefix=/usr --libdir=/usr/lib --sysconfdir=/etc \
	  --localstatedir=/var --bindir=/bin --sbindir=/sbin \
          --disable-static --disable-manpages \
	  --enable-elf-shlibs --disable-libuuid --disable-libblkid \
	  PKG_CONFIG_LIBDIR="$$PWD/../util-linux/FOO/usr/lib/pkgconfig:$$PWD/../eudev/FOO/usr/lib/pkgconfig:$$PWD/../eudev/FOO/usr/share/pkgconfig" \
	  CFLAGS="-I$$PWD/../util-linux/FOO/usr/include -I$$PWD/../util-linux/FOO/usr/include/blkid -I$$PWD/../eudev/FOO/usr/include" \
	  LDFLAGS="-L$$PWD/../util-linux/FOO/usr/lib/ -L$$PWD/../eudev/FOO/usr/lib/" \
	  udev_CFLAGS="-I$$PWD/../eudev/FOO/usr/include" \
	  udev_LIBS="-L$$PWD/../eudev/FOO/usr/lib/ -ludev" && \
	make -j$(JOBCOUNT) && \
	make DESTDIR=$$PWD/FOO install && \
	rm -rf FOO/usr/share && \
	rm -rf FOO/usr/lib/*.a && \
	popd || exit 1


squashfs-tools/FOO:
	pushd squashfs-tools && \
	rm -rf FOO && \
	sed -i \
	    -e 's|^#XZ_SUPPORT|XZ_SUPPORT|' \
	    -e 's|^#LZO_SUPPORT|LZO_SUPPORT|' \
	    -e 's|^#LZ4_SUPPORT|LZ4_SUPPORT|' \
	    -e 's|^#ZSTD_SUPPORT|ZSTD_SUPPORT|' \
	    squashfs-tools/Makefile && \
	make -j$(JOBCOUNT) -C squashfs-tools && \
	make -C squashfs-tools INSTALL_DIR=$$PWD/FOO/sbin \
	  INSTALL_MANPAGES_DIR= install && \
	popd || exit 1


# NOTE: This compiles and links against our freshly built libblkid and
#       libuuid (util-linux) and libudev (eudev).
#
zfs/FOO: util-linux.tar eudev.tar
	pushd zfs && \
	rm -rf FOO && \
	echo "AC_DEFUN([ZFS_AC_KERNEL_TEST_RESULT], [])" >> config/kernel.m4 && \
	./autogen.sh && \
	  ./configure --prefix=/usr --libdir=/usr/lib --sysconfdir=/etc \
	  --localstatedir=/var --bindir=/bin --sbindir=/sbin \
          --disable-static --disable-manpages \
	  --disable-systemd \
	  --enable-linux-builtin \
	  LIBBLKID_CFLAGS="-I$$PWD/../util-linux/FOO/usr/include -I$$PWD/../util-linux/FOO/usr/include/blkid" \
	  LIBBLKID_LIBS="-L$$PWD/../util-linux/FOO/usr/lib/ -lblkid" \
	  LIBUUID_CFLAGS="-I$$PWD/../util-linux/FOO/usr/include -I$$PWD/../util-linux/FOO/usr/include/uuid" \
	  LIBUUID_LIBS="-L$$PWD/../util-linux/FOO/usr/lib/ -luuid" \
	  LIBUDEV_CFLAGS="-I$$PWD/../eudev/FOO/usr/include" \
	  LIBUDEV_LIBS="-L$$PWD/../eudev/FOO/usr/lib/ -ludev" && \
	make -j$(JOBCOUNT) && \
	make DESTDIR=$$PWD/FOO install && \
	rm -rf $$PWD/FOO/usr/include && \
	rm -rf $$PWD/FOO/usr/lib/dracut && \
	rm -rf $$PWD/FOO/usr/share/{initramfs-tools,man} && \
	rm -rf $$PWD/FOO/usr/share/zfs/zfs-tests && \
	popd || exit 1


syslinux-6.03.tar.xz:
	wget https://mirrors.edge.kernel.org/pub/linux/utils/boot/syslinux/$@

# FIXME: the sed statement was added to fix compilation problems on
#        Ubuntu 20.04...  hopefully this isn't needed when we upgrade
#        from upstream.
#
syslinux/FOO: syslinux-6.03.tar.xz
	tar xf $< && \
	mv syslinux-6.03 syslinux && \
	pushd syslinux && \
	sed -i \
	    -e 's|^#include <sys/types.h>|#include <sys/types.h>\n#include <sys/sysmacros.h>|' \
	    extlinux/main.c && \
	make install INSTALLROOT=$$PWD/FOO && \
	popd || exit 1



dropbear/FOO:
	pushd dropbear && \
	rm -rf FOO && \
	sed -i 's|ln -s $$(bindir)/|ln -s |' Makefile.in && \
	autoreconf && \
	./configure --prefix=/usr --libdir=/usr/lib --sysconfdir=/etc \
	  --localstatedir=/var --bindir=/bin --sbindir=/bin \
          --disable-static && \
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


# NOTE: We disable openssl because we've installed dropbear instead of
#       openssl/openssh
#
# FIXME: Ubuntu 18.04 doesn't have a compatible Python commonmark
#       package.  There's a python3-commonmark-bkrs package but it
#       seems like the methods are all capitalized differently... so
#       disabling with --disable-md2man.
#
# NOTE: Ubuntu 18.04 need xxhash and xxhash-dev packages or
#       --disable-xxhash here.
#
# FIXME: We disable zstd support because it looks like bionic's zstd
#        lib is missing some features.
#
rsync/FOO:
	pushd rsync && \
	rm -rf FOO && \
	./prepare-source && \
	sed -i 's|import commonmark|import CommonMark_bkrs as commonmark|' md-convert && \
	./configure --prefix=/usr --libdir=/usr/lib --sysconfdir=/etc \
	  --localstatedir=/var --bindir=/bin --sbindir=/bin \
          --disable-static \
          --disable-openssl --disable-md2man --disable-zstd --disable-debug && \
        make -j$(JOBCOUNT) && make DESTDIR=$$PWD/FOO install && \
	popd || exit 1


efibootmgr/FOO:
	pushd efibootmgr && \
	rm -rf FOO && \
	make EFIDIR=ruckus && \
	make EFIDIR=ruckus DESTDIR=$$PWD/FOO install && \
	popd || exit 1


# FIXME: I'd like to use zstd here, but ubuntu 18.04 squashfs doesn't
#        support it...  I could/should check via configure and use if
#        possible.
#
# NOTE: We include microcode in fw.sqsh so that it will be there
#       post-boot for consistency.  Having the ucode directories in
#       /lib/modules is not enough for early-loading of microcode.
#       That's handled via the generated ucode.img being preppended to
#       our resulting initrd.
#
fw.sqsh:
	mksquashfs linux-firmware $@ -comp xz -e .git -noappend
	mksquashfs wireless-regdb/regulatory.db* $@
	mksquashfs intel-ucode/intel-ucode $@ -keep-as-directory

# NOTE: For early-loading, microcode needs to be provided as an
#       uncompressed cpio archive with specific filenames for Intel
#       and AMD.  Sticking to our "universal initramfs" principles, we
#       include ALL microcode for both vendors in this image.
#
# FIXME: Intel: cating together into bin works, but iucode_tool definately
#        produces something slightly different... and i don't know why.
#
#        iucode_tool -wGenuineIntel.bin /lib/firmware/intel-ucode{,-with-caveats}/
#
DESTFWROOT=$(builddir)/.build_ucode
DESTFWDIR=$(DESTFWROOT)/kernel/x86/microcode
ucode.img:
	$(MKDIR_P) $(DESTFWDIR)
	cat $(srcdir)/linux-firmware/amd-ucode/microcode*.bin > $(DESTFWDIR)/AuthenticAMD.bin
	cat $(srcdir)/intel-ucode/intel-ucode{,-with-caveats}/* > $(DESTFWDIR)/GenuineIntel.bin
	cd $(DESTFWROOT); find . | cpio -o -H newc > $(abs_builddir)/$@
