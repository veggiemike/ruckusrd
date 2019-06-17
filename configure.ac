AC_PREREQ([2.65])
AC_INIT([ruckusrd], [0.12.0], [michael.d.labriola@gmail.com])

AM_INIT_AUTOMAKE([dist-bzip2 no-dist-gzip foreign])

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
# bash, mv, cp, find, cpio, xz, tar, sed, install
#
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
	  tar
	  sed
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


CPUCOUNT=$(grep ^vendor_id /proc/cpuinfo | wc -l)
JOBCOUNT=$((CPUCOUNT+1))
JOBCOUNT_KBUILD=$((CPUCOUNT*4))
AC_SUBST(CPUCOUNT)
AC_SUBST(JOBCOUNT)
AC_SUBST(JOBCOUNT_KBUILD)

AC_CONFIG_FILES([Makefile
		 docs/Makefile
		 src/Makefile
		 subprojects/Makefile
		 src/ruckusrd.conf])
AC_OUTPUT
