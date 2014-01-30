AC_PREREQ([2.65])
AC_INIT([ruckusrd], [0.10.0], [michael.d.labriola@gmail.com])

AM_INIT_AUTOMAKE(dist-bzip2 no-dist-gzip)

AC_PROG_INSTALL
AC_PROG_MKDIR_P
AC_PROG_LN_S


# these programs are required on the host system
AC_DEFUN([NEEDED_PROGS],
	 [dnl progs copied into the initramfs
	  basename
	  blockdev
	  cat
	  chmod
	  cut
	  date
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
	  mkdir
	  mknod
	  modprobe
	  mount
	  pidof
	  readlink
	  rm
	  sed
	  sleep
	  udevd
	  umount
	  vi
	  vol_id
	  switch_root
	  cp
	  mv
	  find
	  chroot
	  fsck
	  e2fsck
	  fsck.ext2
	  fsck.ext3
	  fsck.ext4
	  sort
	  dnl other progs needed for ruckusrd script
	  ldd
	  sed
	  modprobe
	  depmod
	  bash
	  cpio
	  mksquashfs
	 ])

m4_foreach_w([P], NEEDED_PROGS,
  [AC_PATH_PROG(m4_bpatsubst(m4_toupper(P), [\.], [_]), P, [], $PATH:/lib/udev)
   AS_IF([test "$m4_toupper(P)" = ""], [AC_MSG_ERROR([Could not find P])])
   AC_ARG_VAR(m4_bpatsubst(m4_toupper(P), [\.], [_]), Path to P)
  ])

# bash is a special case, because bash sets the variable BASH to $0, which
# results in /bin/sh on tons of systems.
AC_PATH_PROG(BASH_SHELL, bash)
AS_IF([test "$BASH_SHELL" = ""], [AC_MSG_ERROR([Could not find bash])])
AC_ARG_VAR(BASH_SHELL, Path to bash)


# these optional programs can be used to add extra functionality if present
# on the system (e.g, booting off of LVM/RAID), but aren't strictly
# necessary.
AC_DEFUN([OPTIONAL_PROGS],
	 [lvm dnl used in linuxrc to boot off of LVM
	  mdadm dnl used in linuxrc to boot off of RAID
	  tree dnl used by ruckusrd with verbose output
	 ])

m4_foreach_w([P], OPTIONAL_PROGS,
  [AC_PATH_PROG(m4_bpatsubst(m4_toupper(P), [\.], [_]), P, [], $PATH:/lib/udev)
   m4_define([have_p], [])
   m4_append([have_p], [have_])
   m4_append([have_p], m4_bpatsubst(P, [\.], [_]))
   AS_IF([test "$m4_toupper(P)" != ""], [have_p=1], [have_p=0])
   AC_SUBST(have_p)
   AC_ARG_VAR(m4_bpatsubst(m4_toupper(P), [\.], [_]), Path to P)
  ])


# We need either udevadm or udevstart
#
# NOTE: We're trying to stay compatible with older versions of udev here.
#       Really old versions had udevstart and vol_id (in /sbin not
#       /lib/udev) but not udevadm (udevsettle or udevtrigger).  We deal
#       with this by requiring either udevstart or udevadm and substituting
#       the path to whichever is found as the UDEVADM variable.
#
# FIXME: This definately doesn't work on debian squeeze based systems (udev
#        164-3) but does work on suse enterprise 11.1 (udev 128-13.10.1) and
#        really old versions of fedora (tested on 5 (udev 084) and 8 (udev
#        118)).
#
# FIXME: Maybe we should be checking by udev version as apposed to guessing
#        based on what utilities are installed... "udevinfo --version" or
#        "udevadm info --version"
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
#
# NOTE: This only works if we make sure $prefix has been set already...
#       otherwise we end up with NONE in our path.
test "$prefix" = "NONE" && prefix=/usr/local
LINUXRC=$datadir/$PACKAGE/linuxrc
while :; do
    echo $LINUXRC
    temp=`eval echo $LINUXRC`
    test "$temp" = "$LINUXRC" && break
    LINUXRC=$temp
done
AC_SUBST(LINUXRC)

AC_CONFIG_FILES([Makefile
		 docs/Makefile
		 src/Makefile
		 src/linuxrc])

# Do this one seperate, so we can add the chmod
AC_CONFIG_FILES([src/ruckusrd], [chmod +x src/ruckusrd])

AC_OUTPUT
