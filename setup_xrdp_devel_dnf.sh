#!/bin/sh
# Sets up a Debian based machine for xrdp development

cd ~

DISTRIBUTION=$(</etc/redhat-release)
if [ -z "$DISTRIBUTION" ]; then
    DISTRIBUTION=unknown
fi

case "$DISTRIBUTION" in
    Fedora\ release\ 41\ *)
        ;;
    *)  echo "** This script is not tested on $DISTRIBUTION" 2>&2
        exit 1
        ;;
esac

# Development tools
#
# To get meld icons working over X11 forwarding you might have to install
# a Mint theme, or set up a link in ~/.icons. No good workaround has
# been found for this.
set -- \
    /usr/bin/gvim    vim-X11 \
    /usr/bin/meld    meld \
    /usr/bin/astyle  astyle \
    /usr/bin/chronyc  chrony \
    /usr/share/man/man2/waitpid.2.gz man-pages \

PACKAGES=
while [ $# -ge 2 ]; do
    if [ ! -x "$1" ]; then
        PACKAGES="$PACKAGES $2"
    fi
    shift 2
done
if [ -n "$PACKAGES" ]; then
    if [ -x /usr/bin/dnf ]; then
        echo "- installing development tools"
        sudo dnf install -y $PACKAGES || exit $?
    else
        echo "- Can't install$PACKAGES - not a dnf-based system"
    fi
fi

# Allow the testuser to read our home directory
echo "- Setting permissions on home directory"
chmod 751 $HOME || exit $?

# Other changes
echo "- Setting old scrollbar behaviour"
cat <<EOF >~/.config/gtk-3.0/settings.ini
[Settings]
gtk-primary-button-warps-slider = false
EOF

# Repos I can write to
for dir in xrdp xorgxrdp pulseaudio-module-xrdp; do
    if [ ! -d "$dir" ]; then
        echo "- Fetching $dir repo..."
        git clone https://github.com/neutrinolabs/$dir.git || exit $?
        cd $dir
        git remote add matt ssh://git@github.com/matt335672/$dir.git
        case "$dir" in
            xrdp)
                ln -s ../xrdp-scripts/myconfig.sh .
                ;;
        esac
        cd ..
        chmod 755 "$dir" || exit $?
    fi
done

# Repos I can't write to
for dir in NeutrinoRDP; do
    if [ ! -d "$dir" ]; then
        echo "- Fetching $dir repo..."
        git clone https://github.com/neutrinolabs/$dir.git || exit $?
        chmod 755 "$dir" || exit $?
    fi
done

if [ ! -x /usr/bin/dnf ]; then
    echo "- Can't install xrdp dependencies - not a dnf-based system"
else
    echo "- Installing dependencies"
    # xrdp
    sudo dnf install patch gcc make autoconf libtool automake pkgconfig \
        libX11-devel libXfixes-devel libXrandr-devel imlib2-devel openssl \
        pam-devel fuse-devel openssl-devel pixman-devel systemd-devel nasm \
        checkpolicy \
        libjpeg-devel fuse3-devel ibus-devel libxkbfile-devel
fi

if [ ! -x /usr/bin/gmake ]; then
    echo "- Setting up gmake link"
    sudo ln -s make /usr/bin/gmake
fi

echo "- Setting up links to development areas for xorgxrdp"
MODULES_DIR=/usr/lib64/xorg/modules
if [ ! -d $MODULES_DIR ]; then
    MODULES_DIR=/usr/lib/xorg/modules
fi
sudo ln -sf $HOME/xorgxrdp/module/.libs/libxorgxrdp.so $MODULES_DIR/libxorgxrdp.so
sudo ln -sf $HOME/xorgxrdp/xrdpdev/.libs/xrdpdev_drv.so $MODULES_DIR/drivers/xrdpdev_drv.so
sudo ln -sf $HOME/xorgxrdp/xrdpkeyb/.libs/xrdpkeyb_drv.so $MODULES_DIR/input/xrdpkeyb_drv.so
sudo ln -sf $HOME/xorgxrdp/xrdpmouse/.libs/xrdpmouse_drv.so $MODULES_DIR/input/xrdpmouse_drv.so
if [ ! -d /etc/X11/xrdp/ ]; then
    sudo install -dm 755 -o root -g root /etc/X11/xrdp/
fi

sudo ln -sf $HOME/xorgxrdp/xrdpdev/xorg.conf /etc/X11/xrdp/
