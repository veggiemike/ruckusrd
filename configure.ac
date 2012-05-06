AC_PREREQ([2.65])
AC_INIT([ruckusrd], [0.9.0], [michael.d.labriola@gmail.com])

AM_INIT_AUTOMAKE(dist-bzip2 no-dist-gzip)

AC_PROG_INSTALL
AC_PROG_MKDIR_P
AC_PROG_LN_S

AC_DEFUN([NEEDED_PROGS],
	 [dnl progs copied into the initramfs
	  basename
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
	  vi
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

# bash is a special case, because bash sets the variable BASH to $0, which
# results in /bin/sh on tons of systems.
AC_PATH_PROG(BASH_SHELL, bash)
AS_IF([test "BASH" = ""], [AC_MSG_ERROR([Could not find bash])])
AC_ARG_VAR(BASH_SHELL, Path to bash)

# We need either udevadm or udevstart
#
# NOTE: We're trying to stay compatible with older versions of udev here.
#        Really old versions had udevstart and vol_id (in /sbin not /lib/udev)
#        but not udevadm (udevsettle or udevtrigger).  We deal with this by
#        requiring either udevstart or udevadm and substituting the path to
#        whichever is found as the UDEVADM variable.
AC_PATH_PROGS(UDEVADM, [udevadm udevstart])
AS_IF([test "UDEVADM" = ""], [AC_MSG_ERROR([Either udevadm or udevstart are required])])
AC_ARG_VAR(UDEVADM, Path to either udevadm or udevstart)

# In addition to the checked for binary paths, we need to also substitute
# the path to our linuxrc file into the ruckusrd script.  Let's do that via
# configure.
#
# NOTE: Doing this via configure doesn't guarantee that the resuling string
#       has been fully expanded.  In fact, it almost definately guarantees
#       that it won't be.
#
# NOTE: This might not be the best way to fully expand the variable, but it
#       works for me.  It might be portable.  It might not.  Fingers
#       crossed.
pkgdatadir=$datadir/$PACKAGE/linuxrc
while :; do
    temp=`eval echo $pkgdatadir`
    test "$temp" = "$pkgdatadir" && break
    pkgdatadir=$temp
done
AC_SUBST(LINUXRC, $pkgdatadir)

AC_CONFIG_FILES([Makefile \
		 src/Makefile])

# Do this one seperate, so we can add the chmod
AC_CONFIG_FILES([src/ruckusrd], [chmod +x src/ruckusrd])

AC_OUTPUT
