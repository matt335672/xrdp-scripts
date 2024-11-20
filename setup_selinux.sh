#!/bin/sh

PACKAGES=
WORKDIR=$(mktemp -d --tmpdir SELinux.XXXXXXXX)
[ -z "$WORKDIR"] && exit 1
MODULE_TE_SRC="https://src.fedoraproject.org/rpms/xrdp/raw/rawhide/f/xrdp.te"

if ! [ -x /usr/bin/make ]; then
    PACKAGES="$PACKAGES make"
fi

if ! [ -x /usr/share/selinux/devel/Makefile ]; then
    PACKAGES="$PACKAGES selinux-policy-devel"
fi

if [ -n "$PACKAGES" ]; then
    sudo dnf install $PACKAGES || exit $?
fi

cd "$WORKDIR" || exit $?

wget "$MODULE_TE_SRC" || exit $?
for variant in targeted; do
    make NAME="$variant" -f /usr/share/selinux/devel/Makefile
    sudo /usr/sbin/semodule -s "$variant" -i xrdp.pp
    make NAME="$variant" -f /usr/share/selinux/devel/Makefile clean
done

cd ..
rm -rf "$WORKDIR"
exit $?
