# We don't use SUBDIRS here because we don't really wont to join the
# build systems together.  I want to have very specific build scripts
# in here for each subproject.


all: busybox.tar mdadm.tar

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

busybox.tar: busybox/FOO
	tar -C $^ -vcf $@ .


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

mdadm.tar: mdadm/FOO
	tar -C $^ -vcf $@ .
