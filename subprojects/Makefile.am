# We don't use SUBDIRS here because we don't really wont to join the
# build systems together.  I want to have very specific build scripts
# in here for each subproject.


all: busybox.tar

# FIXME: when we add --with-system-busybox to configure, we'll have to
#        conditionally replace this rule w/ one that copies files from
#        the host system.
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

busybox.tar: busybox/FOO
	tar -C $^ -vcf $@ .
