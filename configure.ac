AC_PREREQ([2.65])

m4_define(ruckusrd_major_version, 0)
m4_define(ruckusrd_minor_version, 22)
m4_define(ruckusrd_micro_version, 0)
m4_define(ruckusrd_devtag, [dev])
m4_ifnblank(ruckusrd_devtag,
	[m4_define(ruckusrd_version, ruckusrd_major_version.ruckusrd_minor_version.ruckusrd_micro_version-ruckusrd_devtag)],
	[m4_define(ruckusrd_version, ruckusrd_major_version.ruckusrd_minor_version.ruckusrd_micro_version)])

AC_INIT([RuckusRD], [ruckusrd_version], [veggiemike@sourceruckus.org], [ruckusrd])

AC_SUBST(RUCKUSRD_MAJOR_VERSION, ruckusrd_major_version)
AC_SUBST(RUCKUSRD_MINOR_VERSION, ruckusrd_minor_version)
AC_SUBST(RUCKUSRD_MICRO_VERSION, ruckusrd_micro_version)
AC_SUBST(RUCKUSRD_DEVTAG, ruckusrd_devtag)

AM_INIT_AUTOMAKE([dist-xz no-dist-gzip foreign])

AC_PROG_INSTALL
AC_PROG_MKDIR_P
AC_PROG_LN_S

# ruckusrd doesn't directly need libtool, but if we don't put this
# here, subprojects will fail to find ltmain.sh while bootstrapping
LT_INIT

# check for signalfd() in glibc (added in v2.8 according to its
# manpage), which is needed by newer eudev subproject.  if we don't
# have it, we cannot compile eudev... but we can probalby build the
# old udev-1.42... let's try.
#
# FIXME: should we bother to check for sys/signalfd.h as well?  seems
#        like overkill...
#
AC_CHECK_HEADER([sys/signalfd.h], [],
  [AC_MSG_ERROR([Missing sys/signalfd.h, required by eudev])])
AC_CHECK_FUNC([signalfd], [],
  [AC_MSG_ERROR([Missing signalfd(), required by eudev])])


# Needed to BUILD ruckusrd (not including subprojects)
#
# bash, mv, cp, find, cpio, xz, unxz, gunzip, tar, sed, install, help2man
#
# Extra things needed for building subprojects that have bit me
# (certainly not an exhaustive list)
#
# xpmtoppm (netpbm)
#
# Needed to RUN ruckusrd
#
# bash, mv, cp, find, cpio, xz, ldd, awk, head, modprobe, depmod
#
AC_DEFUN([NEEDED_PROGS],
	 [dnl bash is a special case, see below
	  mv
	  cp
	  find
	  cpio
	  xz
	  unxz
	  gunzip
	  tar
	  sed
	  help2man
	  xpmtoppm
	  ldd
	  awk
	  head
	  modprobe
	  depmod
	 ])

m4_foreach_w([P], NEEDED_PROGS,
  [AC_PATH_PROG(m4_bpatsubst(m4_toupper(P), [\.], [_]), P)
   AS_IF([test "$m4_bpatsubst(m4_toupper(P), [\.], [_])" = ""],
     AC_MSG_ERROR([Could not find P]))
  ])

# bash is a special case, because bash sets the variable BASH to $0, which
# results in /bin/sh on tons of systems.
AC_PATH_PROG(BASH_SHELL, bash)
AS_IF([test "$BASH_SHELL" = ""], [AC_MSG_ERROR([Could not find bash])])

# check for pandoc and disable building of markdown version of manpage
# (only needed so we can see it on the gitweb page)
AC_PATH_PROG(PANDOC, pandoc)
AS_IF([test "$PANDOC" != ""], BUILD_MARKDOWN=yes, BUILD_MARKDOWN=no)
AC_SUBST(BUILD_MARKDOWN)
AM_CONDITIONAL([BUILD_MARKDOWN], [test x$BUILD_MARKDOWN = xyes])


CPUCOUNT=$(grep ^vendor_id /proc/cpuinfo | wc -l)
JOBCOUNT=$((CPUCOUNT+1))
# FIXME: doing CPUCOUNT*4 for KBUILD projects used to be needed in
#        order to peg all cpus do to the recursive nature of
#        KBUILD... that doesn't appear to be needed anymore, and I
#        have no idea when/why that changed.
JOBCOUNT_KBUILD=$((CPUCOUNT+1))
AC_SUBST(CPUCOUNT)
AC_SUBST(JOBCOUNT)
AC_SUBST(JOBCOUNT_KBUILD)

AC_CONFIG_FILES([Makefile
		 docs/Makefile
		 src/Makefile
		 subprojects/Makefile
		 src/ruckusrd.sh])
AC_OUTPUT


# Create a fully expanded variable out of one with embedded path variables.
#
# NOTE: This might not be the best way to fully expand the variable, but it
#       works for me.  It might be portable.  It might not.  Fingers
#       crossed.
#
# NOTE: This only works if we make sure $prefix has been set already...
#       otherwise we end up with NONE in our path.
#
expandit()
{
  test "$prefix" = "NONE" && prefix=/usr/local
  result=$1
  while :; do
    temp=`eval echo $result`
    test "$temp" = "$result" && break
    result=$temp
  done
  echo $result
}


echo
echo
echo
echo "------------------------------------------------------------------------"
echo "$PACKAGE_STRING"
echo "------------------------------------------------------------------------"
echo
echo "Configuration Options Summary:"
echo
echo "Build:"
echo "  CPUCOUNT.............: $CPUCOUNT"
echo "  JOBCOUNT.............: $JOBCOUNT"
echo "  JOBCOUNT_KBUILD......: $JOBCOUNT_KBUILD"
echo
echo "Installation:"
echo "  prefix...............: $prefix"
echo "  pkgdatadir...........: `expandit $datadir/$PACKAGE_TARNAME`"
echo
