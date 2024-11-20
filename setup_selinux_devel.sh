#!/bin/sh

cd $(dirname $0) || exit $?
TE_FILE="$(pwd)/xrdp_devel.te"

if ! [ -f "$TE_FILE" ]; then
    echo "Can't find $TE_FILE" >&2
    exit 1
fi

WORKDIR=$(mktemp -d --tmpdir SELinux.XXXXXXXX)
[ -z "$WORKDIR" ] && exit 1

PACKAGES=

if ! [ -x /usr/bin/make ]; then
    PACKAGES="$PACKAGES make"
fi

if ! [ -f /usr/share/selinux/devel/Makefile ]; then
    PACKAGES="$PACKAGES selinux-policy-devel"
fi

if [ -n "$PACKAGES" ]; then
    sudo dnf install $PACKAGES || exit $?
fi

cd "$WORKDIR" || exit $?
cp "$TE_FILE" . || exit $?

for variant in targeted; do
    make NAME="$variant" -f /usr/share/selinux/devel/Makefile
    sudo /usr/sbin/semodule -s "$variant" -i xrdp_devel.pp
    make NAME="$variant" -f /usr/share/selinux/devel/Makefile clean
done

cd ..
rm -rf "$WORKDIR"
exit $?
