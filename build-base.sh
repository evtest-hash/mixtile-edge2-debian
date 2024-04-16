#!/bin/bash
set -x
WORKDIR="$(pwd)"
ARCHIVE_DIR="$WORKDIR/archives"
DEPLOY_DIR="$WORKDIR/deploy"

UBOOT_VERSION="u-boot-2024.01"
KERNEL_VERSION="linux-6.6.22"

UBOOT_ARCHIVE="${UBOOT_VERSION}.tar.bz2"
KERNEL_ARCHIVE="${KERNEL_VERSION}.tar.xz"

UBOOT_SITE="https://ftp.denx.de/pub/u-boot/${UBOOT_ARCHIVE}"
KERNEL_SITE="https://cdn.kernel.org/pub/linux/kernel/v6.x/${KERNEL_ARCHIVE}"

JOBS=$(nproc)

export ROCKCHIP_TPL="${ARCHIVE_DIR}/rk3568_ddr_1332MHz_v1.16.bin"
export BL31="${ARCHIVE_DIR}/rk3568_bl31_v1.42.elf"

mkdir -p ${ARCHIVE_DIR} ${DEPLOY_DIR}

if [ ! -f "${ARCHIVE_DIR}/${UBOOT_ARCHIVE}" ]; then
    wget -O "${ARCHIVE_DIR}/${UBOOT_ARCHIVE}" "${UBOOT_SITE}"
fi

if [ ! -f "${ARCHIVE_DIR}/${KERNEL_ARCHIVE}" ]; then
    wget -O "${ARCHIVE_DIR}/${KERNEL_ARCHIVE}" "${KERNEL_SITE}"
fi

if [ ! -d "u-boot" ]; then
    tar -xjf "${ARCHIVE_DIR}/${UBOOT_ARCHIVE}"
    mv "${UBOOT_VERSION}" u-boot

    cd "${WORKDIR}/u-boot"
    for i in "${WORKDIR}/patches/u-boot/"*; do patch -p1 < "${i}"; done
    cd "${WORKDIR}"
fi

echo "Building u-boot..."

cd "${WORKDIR}/u-boot"
export ARCH=arm64
export CROSS_COMPILE=aarch64-linux-gnu-
mkdir -p build deploy
make O=build mixtile-edge2-rk3568_defconfig
make O=build -j${JOBS}
cp -v build/idbloader.img deploy/
cp -v build/u-boot.itb deploy/
cd "${WORKDIR}"

if [ ! -d "kernel" ]; then
    tar -xJf "${ARCHIVE_DIR}/${KERNEL_ARCHIVE}"
    mv "${KERNEL_VERSION}" kernel

    cd "${WORKDIR}/kernel"
    for i in "${WORKDIR}/patches/kernel/"*; do patch -Np1 < "${i}"; done
    cp -rf "${WORKDIR}/patches/kernel-overlay/." ./

    cd "${WORKDIR}"
fi

echo "Building kernel..."

cd "${WORKDIR}/kernel"
export ARCH=arm64
export CROSS_COMPILE=aarch64-linux-gnu-
mkdir -p build deploy/modules
make O=build mixtile_edge2_defconfig
make O=build Image -j${JOBS}
make O=build modules -j${JOBS}
make O=build rockchip/rk3568-mixtile-edge2.dtb
cp -v build/arch/arm64/boot/Image deploy/
cp -v build/arch/arm64/boot/dts/rockchip/rk3568-mixtile-edge2.dtb deploy/
make O=build modules_install INSTALL_MOD_PATH="${WORKDIR}/kernel/deploy/modules" INSTALL_MOD_STRIP=1
tar --xform s:'^./':: -czf deploy/kmods.tar.gz -C "${WORKDIR}/kernel/deploy/modules" .
cd "${WORKDIR}"

mkimage -A arm -O linux -T script -C none -a 0 -e 0 -d scripts/mixtile_edge2.bootscript deploy/boot.scr

echo "Base system builds completed."
