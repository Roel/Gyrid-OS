#!/bin/sh

DISTRO="voyage-current"
MOUNT_PROC_SH=/usr/local/sbin/mount-proc.sh

if [ $(uname -m) == "x86_64" ] ; then
	ARCH="_amd64"
	lh_config -a amd64
fi

Chroot ()
{
    # Execute commands in chroot
    chroot "${1}" /usr/bin/env -i HOME="/root" DEBIAN_FRONTEND="noninteractive" \
        TERM="${TERM}" PATH="/usr/sbin:/usr/local/sbin:/usr/bin:/sbin:/bin" \
        ftp_proxy="${LIVE_FTPPROXY}" http_proxy="${LIVE_HTTPPROXY}" ${2}
}

Chroot_MountProc ()
{
    if [ -f ${1}/${MOUNT_PROC_SH} ] ;
    then
        # Execute commands in chroot
        chroot "${1}" /usr/bin/env -i HOME="/root" DEBIAN_FRONTEND="noninteractive" \
			 TERM="${TERM}" PATH="/usr/sbin:/usr/local/sbin:/usr/bin:/sbin:/bin" \
            ftp_proxy="${LIVE_FTPPROXY}" http_proxy="${LIVE_HTTPPROXY}" ${MOUNT_PROC_SH} ${2}
    else
        echo "No ${MOUNT_PROC_SH}, call Chroot() instead"
        Chroot "${1}" "${2}"
    fi
}

BuildTar()
{
	lh_clean
	lh_config -b tar --chroot-filesystem plain -p voyage

	lh_build

	Chroot_MountProc binary/live/filesystem.dir "apt-get -y remove busybox live-initramfs"
	Chroot_MountProc binary/live/filesystem.dir "apt-get -y autoremove"
	rm binary/live/filesystem.dir/boot/*.bak
	
	if [ -d binary/live/filesystem.dir ] ; then
		mv binary/live/filesystem.dir binary/live/$DISTRO$ARCH
		tar -jcf $DISTRO$ARCH.tar.bz2 -C binary/live/	$DISTRO$ARCH/. 
		mv binary/live/$DISTRO$ARCH binary/live/filesystem.dir
	else
		echo "binary/live/filesystem.dir not found!"
	fi
}


BuildISO()
{
	lh_clean
	lh_config -b iso --chroot-filesystem squashfs -p voyage-cd
	lh_build
	
	if [ -f binary.iso ] ; then
		mv binary.iso $DISTRO$ARCH.iso
	else
		echo "binary.iso not found!"
	fi
}

BuildSDK()
{
	lh_clean
	lh_config -b iso --chroot-filesystem squashfs -p voyage-sdk
	lh_build
	
	if [ -f binary.iso ] ; then
		mv binary.iso voyage-sdk$ARCH.iso
	else
		echo "binary.iso not found!"
	fi
}

for TYPE in $1; do
	case "$TYPE" in
		tar)
			BuildTar
		;;
		iso)
			BuildISO
		;;
		sdk)
			BuildSDK
		;;
		test)
			Chroot_MountProc binary/live/filesystem.dir "apt-get -y remove busybox live-initramfs"
			Chroot_MountProc binary/live/filesystem.dir "apt-get -y autoremove"
		;;
		*)
			echo "unknown build type $TYPE"
		;;
	esac
done

