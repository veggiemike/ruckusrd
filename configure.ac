AC_PREREQ([2.65])
AC_INIT([ruckusrd], [0.9.0], [michael.d.labriola@gmail.com])

AM_INIT_AUTOMAKE(dist-bzip2 no-dist-gzip)
#AC_CONFIG_HEADERS([config.h])

# Checks for programs.
# bash
# switch_root
# all the other binaries explicitly copied into initramfs
# mksquashfs

AC_PROG_INSTALL
AC_PATH_PROG(MKSQUASHFS, mksquashfs)

#AC_PATH_PROG(FOO, foo)
#AS_IF([test "$FOO" = ""],
#      [AC_MSG_ERROR([could not find FOO])])
#AC_ARG_VAR(FOO, The FOO)


## I am not sure why I need to do this... but apparently I do.
#if test "$exec_prefix" = "NONE"; then
#    exec_prefix=$prefix
#fi
#
## I am not sure why I need to do this... but apparently I do.
#if test "$exec_prefix" = "NONE"; then
#    exec_prefix=$prefix
#fi
#
#pkglibexecdir=`eval echo "$libexecdir/$PACKAGE"`
#pkglocalstatedir=`eval echo "$localstatedir/$PACKAGE"`
#pkgsharedir=`eval echo "$datarootdir/$PACKAGE"`
#pkglibdir=`eval echo "$libdir/$PACKAGE"`
#
#
#AC_DEFINE_UNQUOTED([LIBEXECDIR], "$pkglibexecdir", [Directory where scripts and binaries live])
#AC_DEFINE_UNQUOTED([LOCALSTATEDIR], "$pkglocalstatedir", [Directory where localstate data lives.])
#AC_DEFINE_UNQUOTED([PKGSHAREDIR], "$pkgsharedir", [Directory where auxiliary files live])
#AC_DEFINE_UNQUOTED([PKGLIBDIR], "$pkglibdir", [Directory where libraries live])
#

#AC_SUBST


AC_CONFIG_FILES([Makefile \
		 src/Makefile])

AC_OUTPUT
