# Process this file with autoconf to produce a configure script.
AC_INIT(cluster, 1.30)
AC_CONFIG_SRCDIR(src/cluster.c)
AM_INIT_AUTOMAKE
AC_CONFIG_HEADERS(config.h)

# Checks for programs.
AC_PROG_CC

# Checks for header files.
AC_HEADER_STDC
AC_CHECK_HEADER(float.h)
AC_CHECK_HEADER(math.h)
AC_CHECK_HEADER(stdio.h)
AC_CHECK_HEADER(stdlib.h)
AC_CHECK_HEADER(string.h)
AC_CHECK_HEADER(time.h)

# Checks for typedefs, structures, and compiler characteristics.
AC_C_CONST
AC_TYPE_SIZE_T

# Checks for library functions.
AC_FUNC_MALLOC
AC_CHECK_LIB([m],[sqrt])
AC_CHECK_LIB([m],[pow])

# Check if we are building the GUI version or the command line version
if test "$with_x" = no; then
  AC_MSG_NOTICE([Building command-line version of Cluster 3.0])
  AM_CONDITIONAL(MOTIF, false)
  AC_CONFIG_FILES([src/Makefile])
else
  AC_MSG_NOTICE([Building GUI version of Cluster 3.0 using Motif])
  AC_PATH_XTRA
  if test x"$no_x" = x"yes"; then
    AC_MSG_ERROR([Failed to locate the X11 include files and libraries.
Use --without-x if you want to build the command-line version of Cluster 3.0.])
  fi
  AM_CONDITIONAL(MOTIF, true)
  AC_CONFIG_FILES([X11/Makefile])
fi

AC_OUTPUT([Makefile])
