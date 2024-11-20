#!/bin/sh

case `uname` in
    Linux)
        : ${CC:=gcc}
        if [ -z "$CFLAGS" ]; then
            case "$CC" in
                clang*)  CFLAGS="-g" ;;
                *)  CFLAGS="-g -fvar-tracking -Wl,-z,now"
                    if grep -q DH_free common/ssl_calls.c; then
                        CFLAGS="$CFLAGS -Wno-error=deprecated-declarations"
                    fi
                    ;;
            esac
        fi
        export CC CFLAGS
        ;;
    FreeBSD)
        : ${CC:=clang} ${CFLAGS:=-g} ${CPPFLAGS:=-I/usr/local/include}
        : ${LDFLAGS:=-L/usr/local/lib}
        export CC CFLAGS CPPFLAGS LDFLAGS
        ;;
    *) echo "**Warning: Unknown platform `uname`" >&2
esac

cd $(dirname $0) || exit $?

if grep -q -- --enable-devel-all ./configure.ac; then
    flags="--disable-devel-all" ;#" --disable-devel-logging"
else
    # xrdp 0.9.16 or earlier
    flags="--enable-xrdpdebug"
fi
flags="$flags --enable-fuse"
flags="$flags --enable-pixman"
flags="$flags --enable-ipv6"
flags="$flags --enable-painter" ; # Shouldn't be necessary
flags="$flags --enable-jpeg"
flags="$flags --with-imlib2"
flags="$flags --enable-vsock"
flags="$flags --with-freetype2"
flags="$flags --enable-ibus"
#flags="$flags --enable-xrdpvr"
#flags="$flags --disable-painter"
#flags="$flags --disable-static"
#flags="$flags --disable-pam --enable-kerberos"
#flags="$flags --disable-pam --enable-pamuserpass"
#flags="$flags --disable-pam --enable-bsd"
#flags="$flags --disable-pam"
#flags="$flags --disable-rfxcodec"
#flags="$flags --enable-apparmor"
flags="$flags --enable-utmp"
flags="$flags --with-libpcsclite"

if [ "$CC" = "g++" ]; then
    CFLAGS="$CFLAGS -g -Werror"
    flags="$flags --disable-neutrinordp"
elif [ "$CC" = "gcc" ]; then
    # If you enable coverage, you can run the tests, then
    # use something like:-
    # cd libipm
    # gcov -o .libs *.c
    #CFLAGS="$CFLAGS -coverage -Wl,-l,gcov"
    flags="$flags --enable-neutrinordp"
elif [ "$CC" = "clang" ]; then
    flags="$flags --enable-neutrinordp"
fi
exec ./configure $flags "$@"
