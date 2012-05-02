AC_PREREQ([2.65])
AC_INIT([ruckusrd], [0.9.0], [michael.d.labriola@gmail.com])

AM_INIT_AUTOMAKE(dist-bzip2 no-dist-gzip)

AC_PROG_INSTALL
AC_PROG_MKDIR_P

AC_DEFUN([NEEDED_PROGS],
	 [dnl progs copied into the initramfs
	  basename
	  bash
	  blockdev
	  cat
	  chmod
	  cut
	  dd
	  dirname
	  dmesg
	  dmsetup
	  echo
	  env
	  grep
	  insmod
	  kill
	  killall5
	  less
	  ln
	  losetup
	  ls
	  lsmod
	  lvm
	  mdadm
	  mkdir
	  mknod
	  modprobe
	  mount
	  pidof
	  readlink
	  rm
	  sed
	  sleep
	  tree
	  udevd
	  umount
	  vol_id
	  switch_root
	  dnl other progs needed for ruckusrd script
	  ldd
	  sed
	  modprobe
	  depmod
	  find
	  bash
	  cpio
	  mksquashfs
	 ])

m4_foreach_w([P], NEEDED_PROGS,
		  [AC_PATH_PROG(m4_toupper(P), P, [], $PATH:/lib/udev)
		   AS_IF([test "$m4_toupper(P)" = ""], [AC_MSG_ERROR([Could not find P])])
		   AC_ARG_VAR(m4_toupper(P), Path to P)])

# we need either udevadm or udevstart
AC_PATH_PROGS(UDEVADM, [udevadm udevstart])
AS_IF([test "UDEVADM" = ""], [AC_MSG_ERROR([Either udevadm or udevstart are required])])
AC_ARG_VAR(UDEVADM, Path to either udevadm or udevstart)

AC_CONFIG_FILES([Makefile \
		 src/Makefile])

AC_OUTPUT
