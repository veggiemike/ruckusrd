# We don't use SUBDIRS here because we don't really wont to join the
# build systems together.  I want to have very specific build scripts
# in here for each subproject.


all-local: util-linux.tar eudev.tar busybox.tar mdadm.tar lvm2.tar e2fsprogs.tar zstd.tar squashfs-tools.tar zfs.tar syslinux.tar dropbear.tar rsync.tar efibootmgr.tar groff.tar less.tar fsarchiver.tar
all-local: fw.sqsh ucode.img

%.tar: %/FOO
	tar -C $^ -vcf $@ .

distclean-local:
	rm -fv {util-linux,eudev,busybox,mdadm,lvm2,e2fsprogs,zstd,squashfs-tools,zfs,syslinux,dropbear,rsync,efibootmgr,groff,less}.tar
	rm -fv fw.sqsh ucode.img
	rm -rf .build*
	cd util-linux && git clean -dfx && git stash
	cd eudev && git clean -dfx && git stash
	cd busybox && git clean -dfx && git stash
	cd mdadm && git clean -dfx && git stash
	cd lvm2 && git clean -dfx && git stash
	cd e2fsprogs && git clean -dfx && git stash
	cd zstd && git clean -dfx && git stash
	cd squashfs-tools && git clean -dfx && git stash
	cd zfs && git clean -dfx && git stash
	rm -rf syslinux-6.03
	cd dropbear && git clean -dfx && git stash
	cd rsync && git clean -dfx && git stash
	cd efibootmgr && git clean -dfx && git stash
	cd groff && git clean -dfx && git stash
	cd less && git clean -dfx && git stash
	cd fsarchiver && git clean -dfx && git stash
	rm -rf syslinux*


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
	  --localstatedir=/var --bindir=/bin --sbindir=/bin \
          --disable-static \
	  --disable-all-programs \
	  --enable-fdisks --enable-libfdisk --enable-libuuid \
	  --enable-libsmartcols --enable-libblkid --enable-blkid \
	  --disable-asciidoc --without-python --without-systemd \
	  --without-btrfs --disable-bash-completion && \
	make -j$(JOBCOUNT) && \
	make DESTDIR=$$PWD/FOO install && \
	rmdir $$PWD/FOO/usr/{bin,sbin} && \
	rm -rf $$PWD/FOO/usr/share && \
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
	  --localstatedir=/var --bindir=/bin --sbindir=/bin \
          --disable-static \
	  --with-rootprefix= \
	  --disable-introspection --disable-selinux \
	  --enable-blkid --enable-kmod \
	  BLKID_CFLAGS="-I$$PWD/../util-linux/FOO/usr/include" \
	  BLKID_LIBS="-L$$PWD/../util-linux/FOO/usr/lib/ -lblkid" && \
	make -j$(JOBCOUNT) && \
	make DESTDIR=$$PWD/FOO install && \
	popd || exit 1


# NOTE: We remove a couple bb symlinks here because some of our other
#       subprojects provide them.  We could stop compiling them by
#       tweaking .config, but this seems easier (and more flexible)
#       for now.
#
# NOTE: For building on jammy (or anything with newer versions of
#       glibc that no longer include rpc/rpc.h), you have to specify
#       additional CFLAGS to get things building.  For jammy, the
#       libtripc-dev package seems to be the one installed by default,
#       so setting CFLAGS=-I/usr/include/tirpc and
#       CONFIG_EXTRA_LDLIBS=tirpc will make it compile with
#       CONFIG_FEATURE_INETD_RPC enabled.  For now, we'll just leave
#       RPC disabled in our .config file.
#
busybox/FOO:
	pushd busybox && \
	rm -rf FOO && \
	make mrproper && \
	cp ../busybox.config .config && \
	make oldconfig && \
	make -j$(JOBCOUNT_KBUILD) && \
	make CONFIG_PREFIX=$$PWD/FOO install && \
	rm -f FOO/bin/{lsattr,chattr,less} && \
	rm -f FOO/sbin/{fdisk,sfdisk,cfdisk,blkid} && \
	rm -f FOO/sbin/{fsck,tune2fs,mke2fs,mkfs.ext2} && \
	mkdir -p FOO/usr/share/udhcpc && \
	cp -va examples/udhcp/{sample,simple}.* FOO/usr/share/udhcpc/ && \
	chmod +x FOO/usr/share/udhcpc/* && \
	sed -i 's|^RESOLV_CONF=.*|RESOLV_CONF="/etc/resolv.conf"|' FOO/usr/share/udhcpc/* && \
	ln -vs sample.script FOO/usr/share/udhcpc/default.script && \
	popd || exit 1


mdadm/FOO:
	pushd mdadm && \
	rm -rf FOO && \
	sed -i 's|-Werror||g' Makefile && \
	make -j$(JOBCOUNT) && \
	make DESTDIR=$$PWD/FOO install && \
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
	  --localstatedir=/var --bindir=/bin --sbindir=/bin \
          --disable-static \
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
	  --localstatedir=/var --bindir=/bin --sbindir=/bin \
          --disable-static \
	  --enable-elf-shlibs --disable-libuuid --disable-libblkid \
	  PKG_CONFIG_LIBDIR="$$PWD/../util-linux/FOO/usr/lib/pkgconfig:$$PWD/../eudev/FOO/usr/lib/pkgconfig:$$PWD/../eudev/FOO/usr/share/pkgconfig" \
	  CFLAGS="-I$$PWD/../util-linux/FOO/usr/include -I$$PWD/../util-linux/FOO/usr/include/blkid -I$$PWD/../eudev/FOO/usr/include" \
	  LDFLAGS="-L$$PWD/../util-linux/FOO/usr/lib/ -L$$PWD/../eudev/FOO/usr/lib/" \
	  udev_CFLAGS="-I$$PWD/../eudev/FOO/usr/include" \
	  udev_LIBS="-L$$PWD/../eudev/FOO/usr/lib/ -ludev" && \
	make -j$(JOBCOUNT) && \
	make DESTDIR=$$PWD/FOO install && \
	rm -rf FOO/usr/lib/*.a && \
	popd || exit 1


zstd/FOO:
	pushd zstd && \
	rm -rf FOO && \
	make -j$(JOBCOUNT) && \
	make DESTDIR=$$PWD/FOO PREFIX=/usr BINDIR=/bin install && \
	rm -rf $$PWD/FOO/usr/lib/*.a && \
	popd || exit 1


# NOTE: The sed statement enables all the additional compressors and
#       points the build at our built zstd subproject.
#
squashfs-tools/FOO: zstd.tar
	pushd squashfs-tools && \
	rm -rf FOO && \
	sed -i \
	    -e 's|^#XZ_SUPPORT|XZ_SUPPORT|' \
	    -e 's|^#LZO_SUPPORT|LZO_SUPPORT|' \
	    -e 's|^#LZ4_SUPPORT|LZ4_SUPPORT|' \
	    -e 's|^#ZSTD_SUPPORT|ZSTD_SUPPORT|' \
	    -e 's|-DZSTD_SUPPORT|-DZSTD_SUPPORT -I /scrap/ruckusrd/subprojects/zstd/FOO/usr/include|' \
	    -e 's|-lzstd|-L /scrap/ruckusrd/subprojects/zstd/FOO/usr/lib -lzstd|' \
	    squashfs-tools/Makefile && \
	make -j$(JOBCOUNT) -C squashfs-tools && \
	make -C squashfs-tools INSTALL_DIR=$$PWD/FOO/bin \
	  INSTALL_MANPAGES_DIR=$$PWD/FOO/usr/share/man/man1 install && \
	popd || exit 1


# NOTE: This compiles and links against our freshly built libblkid and
#       libuuid (util-linux) and libudev (eudev).
#
# NOTE: We remove includes here because it saves us 3.5M and nothing
#       else is compiling against zfs libs.
#
# NOTE: Zfs uses it's own internal zstd implementation and does not
#       depend on our zstd.tar target.
#
zfs/FOO: util-linux.tar eudev.tar
	pushd zfs && \
	rm -rf FOO && \
	echo "AC_DEFUN([ZFS_AC_KERNEL_TEST_RESULT], [])" >> config/kernel.m4 && \
	echo "AC_DEFUN([ZFS_AC_CONFIG_KERNEL], [])" >> config/kernel.m4 && \
	./autogen.sh && \
	  ./configure --prefix=/usr --libdir=/usr/lib --sysconfdir=/etc \
	  --localstatedir=/var --bindir=/bin --sbindir=/bin \
          --disable-static \
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
	rm -rf $$PWD/FOO/usr/share/initramfs-tools && \
	rm -rf $$PWD/FOO/usr/share/zfs/zfs-tests && \
	popd || exit 1


syslinux-6.03.tar.xz:
	wget https://mirrors.edge.kernel.org/pub/linux/utils/boot/syslinux/$@

# FIXME: The sysmacros.h sed statement was added to fix compilation
#        problems on Ubuntu 20.04...  hopefully this isn't needed when
#        we upgrade from upstream.  Oh, there hasn't been an upstream
#        syslinux release in years... :-/
#
# FIXME: The -fcommon sed statement was added to prevent gcc-10 linker
#        errors about multiple definitions of externs.  See
#        https://wiki.syslinux.org/wiki/index.php?title=Building for
#        more discussion.  Hopefully fixed in 6.04 if it ever gets
#        released... :-/
#
# FIXME: Perhaps we should build 6.04-pre3 from git?  I noticed Ubuntu
#        22.04 is using 6.04~git20190206.bf6db5b4+dfsg1-3ubuntu1
#
syslinux/FOO: syslinux-6.03.tar.xz
	tar xf $< && \
	mv syslinux-6.03 syslinux && \
	pushd syslinux && \
	sed -i \
	    -e 's|^#include <sys/types.h>|#include <sys/types.h>\n#include <sys/sysmacros.h>|' \
	    extlinux/main.c && \
	sed -i \
	    -e 's|\(^GCCWARN.*\)|\1 -fcommon|' \
	    mk/syslinux.mk && \
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
# NOTE: This compiles and links against our freshly built libzstd.
#
rsync/FOO: zstd.tar
	pushd rsync && \
	rm -rf FOO && \
	./prepare-source && \
	./configure --prefix=/usr --libdir=/usr/lib --sysconfdir=/etc \
	  --localstatedir=/var --bindir=/bin --sbindir=/bin \
          --disable-static \
          --disable-openssl --disable-md2man --disable-debug \
	  CFLAGS=-I$$PWD/../zstd/FOO/usr/include \
	  LDFLAGS=-L$$PWD/../zstd/FOO/usr/lib && \
        make -j$(JOBCOUNT) && make DESTDIR=$$PWD/FOO install && \
	popd || exit 1


# NOTE: Leaving this at v16 because bionic problems.  Either fix or
#       wait until we've disowned 18.04 to upgrade to v18.
#
efibootmgr/FOO:
	pushd efibootmgr && \
	rm -rf FOO && \
	make EFIDIR=ruckus && \
	make EFIDIR=ruckus DESTDIR=$$PWD/FOO install && \
	popd || exit 1


# FIXME: ugh, gnulib.  i think this is the only thing using it at this
#        point, but if we end up with multiple subprojects all cloning
#        gnulib we should pull it out and have a single instance in
#        subprojects/gnulib
#
#        does git clean -dfx nuke the clone? no, it doesn't.
#
# NOTE: We delete /usr/share/doc because it's 12M of html/pdf docs
#       we'll never see.
#
groff/FOO:
	pushd groff && \
	rm -rf FOO && \
	./bootstrap && \
	./configure --prefix=/usr --libdir=/usr/lib --sysconfdir=/etc \
	  --localstatedir=/var --bindir=/bin --sbindir=/bin \
          --disable-static && \
        make -j$(JOBCOUNT) && make DESTDIR=$$PWD/FOO install && \
	rm -rf $$PWD/FOO/usr/share/doc/ && \
	popd || exit 1


less/FOO:
	pushd less && \
	rm -rf FOO && \
	sed -i '/lesstest\/Makefile echo_distfiles/d' Makefile.aut && \
	make -f Makefile.aut distfiles && \
	./configure --prefix=/usr --libdir=/usr/lib --sysconfdir=/etc \
	  --localstatedir=/var --bindir=/bin --sbindir=/bin \
          --disable-static && \
        make -j$(JOBCOUNT) && \
	make DESTDIR=$$PWD/FOO install && \
	popd || exit 1


# NOTE: This compiles and links against our freshly built libblkid and
#       libuuid (util-linux), libext2fs, libcom_err, and libe2p
#       (e2fsprogs), and libzstd (zstd).
#
fsarchiver/FOO: util-linux.tar e2fsprogs.tar zstd.tar
	pushd fsarchiver && \
	rm -rf FOO && \
	./autogen.sh && \
	./configure --prefix=/usr --libdir=/usr/lib --sysconfdir=/etc \
	  --localstatedir=/var --bindir=/bin --sbindir=/bin \
          --disable-static \
	  CFLAGS="-I$$PWD/../zstd/FOO/usr/include" \
	  LDFLAGS="-L$$PWD/../zstd/FOO/usr/lib/" \
	  BLKID_CFLAGS="-I$$PWD/../util-linux/FOO/usr/include -I$$PWD/../util-linux/FOO/usr/include/blkid" \
	  BLKID_LIBS="-L$$PWD/../util-linux/FOO/usr/lib/ -lblkid" \
	  UUID_CFLAGS="-I$$PWD/../util-linux/FOO/usr/include -I$$PWD/../util-linux/FOO/usr/include/uuid" \
	  UUID_LIBS="-L$$PWD/../util-linux/FOO/usr/lib/ -luuid" \
	  EXT2FS_CFLAGS="-I$$PWD/../e2fsprogs/FOO/usr/include -I$$PWD/../e2fsprogs/FOO/usr/include/ext2fs" \
	  EXT2FS_LIBS="-L$$PWD/../e2fsprogs/FOO/usr/lib/ -lext2fs" \
	  COM_ERR_CFLAGS="-I$$PWD/../e2fsprogs/FOO/usr/include" \
	  COM_ERR_LIBS="-L$$PWD/../e2fsprogs/FOO/usr/lib/ -lcom_err" \
	  E2P_CFLAGS="-I$$PWD/../e2fsprogs/FOO/usr/include -I$$PWD/../e2fsprogs/FOO/usr/include/e2p" \
	  E2P_LIBS="-L$$PWD/../e2fsprogs/FOO/usr/lib/ -le2p" && \
        make V=1 -j$(JOBCOUNT) && \
	make DESTDIR=$$PWD/FOO install && \
	popd || exit 1


# NOTE: We use the mksquashfs we've built against our libztd to ensure
#       that old systems (e.g., Ubuntu 18.04) have a working mksquashfs
#       that can use zstd.  The resulting .sqsh file is slightly
#       larger, but unpacks faster during boot.
#
# NOTE: We include microcode in fw.sqsh so that it will be there
#       post-boot for consistency.  Having the ucode directories in
#       /lib/modules is not enough for early-loading of microcode.
#       That's handled via the generated ucode.img being preppended to
#       our resulting initrd.
#
fw.sqsh: squashfs-tools.tar
	LD_LIBRARY_PATH=$PWD/zstd/FOO/usr/lib \
	  ./squashfs-tools/FOO/bin/mksquashfs linux-firmware $@ -comp zstd -e .git -noappend
	LD_LIBRARY_PATH=$PWD/zstd/FOO/usr/lib \
	  ./squashfs-tools/FOO/bin/mksquashfs wireless-regdb/regulatory.db* $@
	LD_LIBRARY_PATH=$PWD/zstd/FOO/usr/lib \
	  ./squashfs-tools/FOO/bin/mksquashfs intel-ucode/intel-ucode $@ -keep-as-directory


# NOTE: For early-loading, microcode needs to be provided as an
#       uncompressed cpio archive with specific filenames for Intel
#       and AMD.  Sticking to our "universal initramfs" principles, we
#       include ALL microcode for both vendors in this image.
#
# FIXME: Intel: cating together into bin works, but iucode_tool definitely
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
