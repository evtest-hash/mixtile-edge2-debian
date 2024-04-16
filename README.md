# Mixtile mainline Debian Linux system image building 

## System Requirements:

Debian 12(Bookworm) / Ubuntu 22.04 (Jammy) or above

## Install Dependency:

```shell
sudo apt-get update && sudo apt-get upgrade -y
sudo apt-get install -y build-essential gcc-aarch64-linux-gnu bison \
qemu-user-static qemu-system-arm qemu-efi u-boot-tools binfmt-support \
debootstrap flex libssl-dev bc rsync kmod cpio xz-utils fakeroot parted \
udev dosfstools uuid-runtime git-lfs device-tree-compiler python2 python3 \
python-is-python3 fdisk bc debhelper python3-pyelftools python3-setuptools \
python3-distutils python3-pkg-resources swig libfdt-dev libpython3-dev
```
## Build System Images:

### 1. Build u-boot & kernel:
```shell
./build-base.sh
```
### 2. Build minimal Debian system image, output image: deploy/rk3568-mixtile-edge2-debian-minimal.img.gz

```shell
sudo ./build-image-debian-minimal.sh
```

### 3. Build full-size Debian system image, output image: deploy/rk3568-mixtile-edge2-debian-full.img.gz
```shell
sudo ./build-image-debian-full.sh
```
### 4. Build minimal Ubuntu system image, output image: deploy/rk3568-mixtile-edge2-ubuntu-minimal.img.gz
```shell
sudo ./build-image-ubuntu-minimal.sh
```
### 5. Build full-size Ubuntu system image, output image: deploy/rk3568-mixtile-edge2-ubuntu-full.img.gz
```shell
sudo ./build-image-ubuntu-full.sh
```
System image should be uncompressed by xz before being installed to device.

## Prepare upgrade tool:
```shell
git clone https://github.com/rockchip-linux/rkdeveloptool.git
cd rkdeveloptool
sudo apt-get install libudev-dev libusb-1.0-0-dev dh-autoreconf
aclocal
autoreconf -i
autoheader
automake --add-missing
./configure
make
```
## Install system image to device:
```shell
wget https://downloads.mixtile.com/edge2/MiniLoaderAll.bin
sudo ./rkdeveloptool db MiniLoaderAll.bin
sudo ./rkdeveloptool wl 0 system.img #Replace system.img to the uncompressed system image you get.
sudo ./rkdeveloptool rd
```