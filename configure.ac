AC_PREREQ([2.65])
AC_INIT([ruckusrd], [0.11.2], [michael.d.labriola@gmail.com])

AM_INIT_AUTOMAKE(dist-bzip2 no-dist-gzip)

AC_PROG_INSTALL
AC_PROG_MKDIR_P
AC_PROG_LN_S


# these programs are required on the host system
AC_DEFUN([NEEDED_PROGS],
	 [dnl all progs are copied into the initramfs
	  basename
	  blockdev
	  cat
	  chmod
	  chroot
	  cp
	  cpio
	  cut
	  date
	  dd
	  depmod
	  dirname
	  dmesg
	  dmsetup
	  e2fsck
	  echo
	  env
	  fdisk
	  find
	  fsck
	  fsck.ext2
	  fsck.ext3
	  fsck.ext4
	  grep
	  gzip
	  head
	  insmod
	  kill
	  killall5
	  ldd
	  less
	  ln
	  losetup
	  ls
	  lsmod
	  mkdir
	  mknod
	  mksquashfs
	  modinfo
	  modprobe
	  mount
	  mv
	  pidof
	  ps
	  readlink
	  rm
	  rmmod
	  sed
	  sleep
	  sort
	  switch_root
	  tail
	  udevd
	  umount
	  vi
	  zcat
	 ])

m4_foreach_w([P], NEEDED_PROGS,
  [AC_PATH_PROG(m4_bpatsubst(m4_toupper(P), [\.], [_]), P)
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
  [AC_PATH_PROG(m4_bpatsubst(m4_toupper(P), [\.], [_]), P)
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
#       /lib/udev) but not udevadm (udevsettle or udevtrigger).  We'll check
#       for udevadm 1st, then check for udevstart if needed.  In linuxrc,
#       we'll key on have_udevadm to tweak usage.
have_udevadm=0
have_udevstart=0
AC_PATH_PROG(UDEVADM, [udevadm])
AS_IF([test "$UDEVADM" != ""],
  [have_udevadm=1],
  [AC_PATH_PROG(UDEVSTART, [udevstart])
   AS_IF([test "$UDEVSTART" != ""],
     [have_udevstart=1],
     [AC_MSG_ERROR([Either udevadm or udevstart are required])
     ])
  ])
AC_SUBST(have_udevadm)
AC_SUBST(have_udevstart)
AC_ARG_VAR(UDEVADM, [Path to udevadm])
AC_ARG_VAR(UDEVSTART, [Path to udevstart (udevadm is prefered)])

# We need either blkid or vol_id
#
# NOTE: Similar to the udevadm vs udevstart check, really old versions of
#       udev depended on vol_id, which eventually got removed once blkid was
#       added to util-linux.  We'll check for blkid 1st, then check for
#       vol_id if blkid isn't found.  In linuxrc, we'll have to key on
#       have_blkid to change the udev rule syntax accordingly.
have_blkid=0
have_vol_id=0
AC_PATH_PROG(BLKID, [blkid])
AS_IF([test "$BLKID" != ""],
  [have_blkid=1],
  [AC_PATH_PROG(VOL_ID, [vol_id], [], $PATH:/lib/udev)
   AS_IF([test "$VOL_ID" != ""],
     [have_vol_id=1],
     [AC_MSG_ERROR([Either blkid or vol_id are required])
     ])
  ])
AC_SUBST(have_blkid)
AC_SUBST(have_vol_id)
AC_ARG_VAR(BLKID, [Path to blkid])
AC_ARG_VAR(VOL_ID, [Path to vol_id (blkid is prefered)])


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
    #echo $LINUXRC
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
