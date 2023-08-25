#!/bin/bash
# Script outline to install and build kernel.
# Author: Siddhant Jajoo.

set -e
set -u
echo "starting manual-linux.sh"
CURRDIR=$(pwd)
OUTDIR=/tmp/aesd
KERNEL_REPO=https://git.kernel.org/pub/scm/linux/kernel/git/stable/linux-stable.git
KERNEL_VERSION=v5.1.10
BUSYBOX_VERSION=1_36_0
FINDER_APP_DIR=$(realpath $(dirname $0))
ARCH=arm64
CROSS_COMPILE=aarch64-none-linux-gnu-
toolchain=/usr/local/arm-cross-compiler/install/gcc-arm-10.2-2020.11-x86_64-aarch64-none-linux-gnu/
export PATH=$PATH:$toolchain/bin/
if [ $# -lt 1 ]
then
	echo "Using default directory ${OUTDIR} for output"
else
	OUTDIR=$1
	echo "Using passed directory ${OUTDIR} for output"
fi

mkdir -p ${OUTDIR}

cd "$OUTDIR"
if [ ! -d "${OUTDIR}/linux-stable" ]; then
    #Clone only if the repository does not exist.
	echo "CLONING GIT LINUX STABLE VERSION ${KERNEL_VERSION} IN ${OUTDIR}"
	git clone ${KERNEL_REPO} --depth 1 --single-branch --branch ${KERNEL_VERSION}
fi
if [ ! -e ${OUTDIR}/linux-stable/arch/${ARCH}/boot/Image ]; then
    cd linux-stable
    echo "Checking out version ${KERNEL_VERSION}"
    git checkout ${KERNEL_VERSION}

    # TODO: Add your kernel build steps here
    make ARCH=arm64 CROSS_COMPILE=aarch64-none-linux-gnu- mrproper
    git reset --hard
    patch -p1 < ${CURRDIR}/patch_solution_for_current_linux_version.patch 
    make -j4 ARCH=${ARCH} CROSS_COMPILE=${CROSS_COMPILE} defconfig 
    make -j4 ARCH=${ARCH} CROSS_COMPILE=${CROSS_COMPILE} Image 
fi

cp ${OUTDIR}/linux-stable/arch/arm64/boot/Image ${OUTDIR}/

echo "Adding the Image in outdir"

echo "Creating the staging directory for the root filesystem"
cd "$OUTDIR"
if [ -d "${OUTDIR}/rootfs" ]
then
	echo "Deleting rootfs directory at ${OUTDIR}/rootfs and starting over"
    sudo rm  -rf ${OUTDIR}/rootfs
fi

# TODO: Create necessary base directories
mkdir rootfs
cd $OUTDIR/rootfs/
mkdir -p bin etc dev lib home lib64 proc sbin sys tmp usr var
mkdir -p usr/bin usr/lib usr/sbin
mkdir -p var/log
mkdir -p conf
mkdir -p home/conf

cd "$OUTDIR"
if [ ! -d "${OUTDIR}/busybox" ]
then
git clone git://busybox.net/busybox.git
    cd busybox
    git checkout ${BUSYBOX_VERSION}
    # TODO:  Configure busybox
    make distclean
    make defconfig
    make ARCH=${ARCH} CROSS_COMPILE=${CROSS_COMPILE} 
    
else
    cd busybox
fi

# TODO: Make and install busybox
make CONFIG_PREFIX="$OUTDIR/busybox"  ARCH=${ARCH} CROSS_COMPILE=${CROSS_COMPILE} install

echo "Library dependencies"
${CROSS_COMPILE}readelf -a bin/busybox | grep "program interpreter"
${CROSS_COMPILE}readelf -a bin/busybox | grep "Shared library"

# TODO: Add library dependencies to rootfs
cp -rf bin $OUTDIR/rootfs
cp -rf usr/bin $OUTDIR/rootfs/usr
cp $toolchain/aarch64-none-linux-gnu/libc/lib/ld-linux-aarch64.so.1 $OUTDIR/rootfs/lib/
cp -rf $toolchain/aarch64-none-linux-gnu/libc/lib64 $OUTDIR/rootfs/


cd $OUTDIR/rootfs/
# TODO: Make device nodes
mknod -m 0666 dev/null c 1 3
mknod -m 0600 dev/console c 5 1
# TODO: Clean and build the writer utility
# TODO: Copy the finder related scripts and executables to the /home directory
# on the target rootfs
cd $FINDER_APP_DIR
make clean
make CROSS_COMPILE=${CROSS_COMPILE}
sudo cp   writer   $OUTDIR/rootfs/home/
sudo cp   finder-test.sh $OUTDIR/rootfs/home/
sudo cp   autorun-qemu.sh $OUTDIR/rootfs/home/
sudo cp   finder.sh $OUTDIR/rootfs/home/
sudo cp   ./conf/*   $OUTDIR/rootfs/conf
sudo cp   ./conf/*   $OUTDIR/rootfs/home/conf

# TODO: Chown the root directory
# TODO: Create initramfs.cpio.gz
cd $OUTDIR/rootfs
find . | cpio -H newc -ov --owner root:root > ${OUTDIR}/initramfs.cpio
gzip -f $OUTDIR/initramfs.cpio
