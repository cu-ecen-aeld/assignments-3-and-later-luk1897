#!/bin/bash
# Script outline to install and build kernel.
# Author: Siddhant Jajoo.

set -e
set -u

OUTDIR=/tmp/aeld
KERNEL_REPO=git://git.kernel.org/pub/scm/linux/kernel/git/stable/linux-stable.git
KERNEL_VERSION=v5.15.163
BUSYBOX_VERSION=1_33_1
FINDER_APP_DIR=$(realpath $(dirname $0))
ARCH=arm64
CROSS_COMPILE=aarch64-none-linux-gnu-


if [ $# -lt 1 ]
then
	echo "Using default directory ${OUTDIR} for output"
else
	OUTDIR=$1
	echo "Using passed directory ${OUTDIR} for output"
fi

mkdir -p ${OUTDIR}

if [ -d "${OUTDIR}" ]; then
    echo "Directory ${OUTDIR} created/exists"
else
    echo "Impossible to create directory ${OUTDIR}"
    exit 1
fi

cd "$OUTDIR"
if [ ! -d "${OUTDIR}/linux-stable" ]; then
    #Clone only if the repository does not exist.
	echo "CLONING GIT LINUX STABLE VERSION ${KERNEL_VERSION} IN ${OUTDIR}"
	git clone ${KERNEL_REPO} --depth 1 --single-branch --branch ${KERNEL_VERSION}
fi
if [ ! -e "${OUTDIR}/linux-stable/arch/${ARCH}/boot/Image" ]; then
    cd linux-stable
    echo "Checking out version ${KERNEL_VERSION}"
    git checkout ${KERNEL_VERSION}

    # TODO: Add your kernel build steps here
    make ARCH=${ARCH} CROSS_COMPILE=${CROSS_COMPILE} mrproper
    make ARCH=${ARCH} CROSS_COMPILE=${CROSS_COMPILE} defconfig
    make -j4 ARCH=${ARCH} CROSS_COMPILE=${CROSS_COMPILE} all
    make ARCH=${ARCH} CROSS_COMPILE=${CROSS_COMPILE} dtbs

fi

echo "Adding the Image in outdir"


if [ ! -e "${OUTDIR}/Image" ]; then
    cp ${OUTDIR}/linux-stable/arch/${ARCH}/boot/Image ${OUTDIR}
fi

echo "Creating the staging directory for the root filesystem"
cd "$OUTDIR"
if [ -d "${OUTDIR}/rootfs" ]
then
	echo "Deleting rootfs directory at ${OUTDIR}/rootfs and starting over"
    sudo rm  -rf ${OUTDIR}/rootfs
fi

# TODO: Create necessary base directories

mkdir rootfs 
cd rootfs

mkdir -p bin dev etc home lib lib64 proc sys sbin tmp usr var
mkdir -p usr/bin usr/lib usr/sbin
mkdir -p var/log

cd "$OUTDIR"
if [ ! -d "${OUTDIR}/busybox" ]
then
git clone git://busybox.net/busybox.git
    cd busybox
    git checkout ${BUSYBOX_VERSION}
    # TODO:  Configure busybox
    make distclean
    make defconfig
else
    cd busybox
fi

# TODO: Make and install busybox

 make ARCH=${ARCH} CROSS_COMPILE=${CROSS_COMPILE}
 make CONFIG_PREFIX=${OUTDIR}/rootfs ARCH=${ARCH} CROSS_COMPILE=${CROSS_COMPILE} install


cd "${OUTDIR}/rootfs"

echo "Library dependencies"
${CROSS_COMPILE}readelf -a bin/busybox | grep "program interpreter"
${CROSS_COMPILE}readelf -a bin/busybox | grep "Shared library"

# TODO: Add library dependencies to rootfs


so1=$(find toolchain/ -name "ld-linux-aarch64.so.1")
so2=$(find toolchain/ -name "libm.so.6")
so3=$(find toolchain/ -name "libresolv.so.2")
so4=$(find toolchain/ -name "libc.so.6")

cp "$so1" "$OUTDIR/rootfs/lib"
cp "$so2" "$OUTDIR/rootfs/lib64"
cp "$so3" "$OUTDIR/rootfs/lib64"
cp "$so4" "$OUTDIR/rootfs/lib64"

# TODO: Make device nodes

if [ ! -e "${OUTDIR}/rootfs/dev/null" ]; then
    sudo mknod -m 666 dev/null c 1 3
fi 

if [ ! -e "${OUTDIR}/rootfs/dev/console" ]; then
    sudo mknod -m 666 dev/console c 5 1
fi


# TODO: Clean and build the writer utility

P2=/home/luk/Desktop/assignment-2-luk1897
P3=/home/luk/Desktop/assignments-3-and-later-luk1897

if [ ! -e "${OUTDIR}/rootfs/home/Makefile" ]; then
    cp "${FINDER_APP_DIR}/Makefile" "${OUTDIR}/rootfs/home/"
fi

if [ ! -e "${OUTDIR}/rootfs/home/writer.c" ]; then
    cp "${FINDER_APP_DIR}/writer.c" ${OUTDIR}/rootfs/home/
fi

cd ${OUTDIR}/rootfs/home

make clean
make CROSS_COMPILE=${CROSS_COMPILE}

# TODO: Copy the finder related scripts and executables to the /home directory
# on the target rootfs

if [ ! -d "${OUTDIR}/rootfs/home/conf" ]; then
    mkdir -p "${OUTDIR}/rootfs/home/conf" 
fi

if [ ! -e "${OUTDIR}/rootfs/home/finder.sh" ]; then
    cp "${FINDER_APP_DIR}/finder.sh" "${OUTDIR}/rootfs/home/"
fi

if [ ! -e "${OUTDIR}/rootfs/home/conf/username.txt" ]; then
    cp "${FINDER_APP_DIR}/username.txt" "${OUTDIR}/rootfs/home/conf"
fi

if [ ! -e "${OUTDIR}/rootfs/home/conf/assignment.txt" ]; then
    cp "${FINDER_APP_DIR}/assignment.txt" "${OUTDIR}/rootfs/home/conf"
fi

if [ ! -e "${OUTDIR}/rootfs/home/finder-test.sh" ]; then
    cp "${FINDER_APP_DIR}/finder-test.sh" "${OUTDIR}/rootfs/home/"
fi

if [ ! -e "${OUTDIR}/rootfs/home/autorun-qemu.sh" ]; then
    cp "${FINDER_APP_DIR}/autorun-qemu.sh" "${OUTDIR}/rootfs/home/"
fi


# TODO: Chown the root directory

#sudo chown -R root:root ${OUTDIR}/rootfs


# TODO: Create initramfs.cpio.gz

cd "${OUTDIR}/rootfs"

find . | cpio -H newc -ov --owner root:root > ${OUTDIR}/initramfs.cpio

gzip -f ${OUTDIR}/initramfs.cpio
