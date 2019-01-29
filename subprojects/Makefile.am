# We don't use SUBDIRS here because we don't really wont to join the
# build systems together.  I want to have very specific build scripts
# in here for each subproject.


all: busybox.tar mdadm.tar lvm2.tar

%.tar: %/FOO
	tar -C $^ -vcf $@ .

clean:
	rm -fv {busybox,mdadm,lvm2}.tar
	cd busybox && git clean -dfx
	cd mdadm && git clean -dfx
	cd lvm2 && git clean -dfx


# FIXME: when we add --with-system-busybox to configure, we'll have to
#        conditionally replace this rule w/ one that copies files from
#        the host system.
#
# FIXME: play with busybox.config to make things smaller.  right now,
#        we're installing everything under the sun.  also, we might
#        get smaller size if we switch to hard links.
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
#        eudev.
#
lvm2/FOO:
	pushd lvm2 && \
	./configure --prefix=/usr && \
	make -j$(JOBCOUNT) && \
	make DESTDIR=$$PWD/FOO install && \
	rm -rf FOO/usr/{include,share} && \
	popd || exit 1
