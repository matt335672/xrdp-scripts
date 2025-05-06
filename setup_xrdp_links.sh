#!/bin/sh

if [ -x /usr/sbin/getenforce ]; then
    echo "- Running on an SELinux system"
    if ! [ -x /usr/sbin/semanage -a -x /usr/sbin/restorecon ]; then
        echo "** Need semanage/restorecon commands to relabel filesystem" >&2
        exit 1
    fi
    do_sudo_semanage()
    {
        sudo semanage fcontext --add -t "$1" -f f "$2"
        sudo restorecon "$2"
    }
else
    do_sudo_semanage()
    {
        :
    }
fi

echo "- Setting up library links"
cd /usr/local/lib/xrdp || exit $?
for file in *.so*; do
    if [ -h $file ]; then
        :
    elif [ -f $file ]; then
	dest=$(find ~/xrdp -type f -name $file)
	set -- $dest
	if [ $# -eq 0 ]; then
            echo "** Can't find file for $file" >&2
            exit 1
        elif [ $# -gt 1 ]; then
            echo "** Found multiple matches for $file" >&2
            exit 1
        else
            set -- $(file -b $dest)
            if [ $1 != ELF ]; then
                echo "Link $dest is not an ELF file" >&2
                exit 1
            else
                sudo ln -sf $dest $file
                do_sudo_semanage lib_t $dest
            fi
        fi
    fi
done
cd /usr/local/lib || exit %?
for file in libpcsclite-xrdp.so.0.0.0; do
    if [ -f $file ]; then
	dest=$(find ~/xrdp -type f -name $file)
	set -- $dest
	if [ $# -eq 0 ]; then
            echo "** Can't find file for $file" >&2
            exit 1
        elif [ $# -gt 1 ]; then
            echo "** Found multiple matches for $file" >&2
            exit 1
        else
            set -- $(file -b $dest)
            if [ $1 != ELF ]; then
                echo "Link $dest is not an ELF file" >&2
                exit 1
            else
                sudo ln -sf $dest $file
                do_sudo_semanage lib_t $dest
            fi
        fi
    fi
done


echo "- Setting up binary links"
set -- \
    SETDIR          /usr/local/bin \
    xrdp-genkeymap  genkeymap/ \
    xrdp-keygen     keygen/.libs/ \
    xrdp-mkfv1      fontutils/.libs/ \
    xrdp-dumpfv1    fontutils/.libs/ \
    xrdp-dis        sesman/tools/.libs/ \
    xrdp-sesadmin   sesman/tools/.libs/ \
    xrdp-sesrun     sesman/tools/.libs/ \
    SETDIR          /usr/local/sbin \
    xrdp            xrdp/.libs/ \
    xrdp-sesman     sesman/.libs/ \
    xrdp-chansrv     sesman/chansrv/.libs/ \
    SETDIR          /usr/local/libexec/xrdp \
    waitforx        waitforx/.libs/\
    xrdp-droppriv   tools/chkpriv/.libs/ \
    xrdp-sesexec    sesman/sesexec/.libs/

while [ $# -ge 2 ]; do
    if [ $1 = SETDIR ]; then
        cd $2 || exit $?
    else
        dest=$HOME/xrdp/$2$1
        if [ ! -x $dest ]; then
            echo "** Warning: Can't find target $dest" >&2
        fi
        sudo ln -sf $dest ./$1
        do_sudo_semanage bin_t $dest
    fi
    shift 2
done

echo "- Setting up /usr/local/share/xrdp links"
cd /usr/local/share/xrdp || exit $?
for file in sans-10.fv1 sans-18.fv1; do
    sudo ln -sf $HOME/xrdp/xrdp/$file .
done
sudo ln -sf $HOME/xrdp/tools/chkpriv/xrdp-chkpriv .

echo "- Setting up /usr/local/include links"
cd /usr/local/include || exit $?
sudo rm -r ms-*.h xrdp_*.h
sudo ln -s ~/xrdp/common/ms-*.h ~/xrdp/common/xrdp_*.h .

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
