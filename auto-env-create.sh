#!/bin/bash

set -e

MANAGARM_BASE_DIR=$(pwd)/managarm
MANAGARM_META_PACKAGE=weston-desktop

while getopts 'd:p:h' opt; do
  case "$opt" in
  d)
    MANAGARM_BASE_DIR=$(pwd)/${OPTARG}
    ;;
  p)
    MANAGARM_META_PACKAGE=${OPTARG}
    ;;
  h)
    echo "Usage: $(basename $0) [-d managarm_base_dir] [-p meta-package]"
    echo "By default, creates a new managarm tree into a folder named 'managarm', with meta-package 'weston-desktop'."
    exit 0
    ;;
  :)
    echo -e "option requires an argument.\nCheck the help section with $(basename $0) -h!"
    exit 1
    ;;
  ?)
    echo -e "invalid command option.\nCheck the help section with $(basename $0) -h!"
    exit 1
    ;;
  esac
done

echo "Building managarm tree into directory ${MANAGARM_BASE_DIR}"
echo -e "\t- Using meta-package ${MANAGARM_META_PACKAGE}"

MANAGARM_BUILD_DIR=$MANAGARM_BASE_DIR/build
MANAGARM_SRC_DIR=$MANAGARM_BASE_DIR/src
MANAGARM_ROOTFS_PATH=$MANAGARM_BASE_DIR/rootfs

if ! [ -z "$(ls -A $MANAGARM_BASE_DIR)" ]; then
  echo "auto-create-env: managarm folder not empty! giving you a few seconds to exit the script..."
  sleep 3
  echo "auto-create-env: ok, continuing!"
  rm -rf $MANAGARM_BASE_DIR
fi

mkdir -p $MANAGARM_BASE_DIR

cd $MANAGARM_BASE_DIR
if ! command -v xbstrap &> /dev/null
then
  echo "auto-create-env: installing xbstrap"
  pip3 install xbstrap
  echo "auto-create-env: updating xbstrap prereqs"
  xbstrap prereqs cbuildrt xbps
fi

echo "auto-create-env: cloning bootstrap-managarm"
git clone https://github.com/managarm/bootstrap-managarm.git src
mkdir -p build
if ! [ -f "../managarm-rootfs.tar.gz" ]; then
  echo "auto-create-env: downloading rootfs"
  curl https://repos.managarm.org/buildenv/managarm-buildenv.tar.gz -o ../managarm-rootfs.tar.gz
fi
echo "auto-create-env: extracting rootfs"
tar xf ../managarm-rootfs.tar.gz
echo "auto-create-env: setting up build folder"
touch $MANAGARM_BUILD_DIR/bootstrap-size.yml
cat > $MANAGARM_BUILD_DIR/bootstrap-site.yml << EOF
pkg_management:
  format: xbps

container:
  runtime: cbuildrt
  rootfs:  $MANAGARM_ROOTFS_PATH
  uid: 1000
  gid: 1000
  src_mount: /var/lib/managarm-buildenv/src
  build_mount: /var/lib/managarm-buildenv/build
  allow_containerless: true
define_options:
  mount-using: 'loopback'
EOF
$( cd $MANAGARM_BUILD_DIR; xbstrap init ../src )
echo "auto-create-env: pulling packages required for meta-package ${MANAGARM_META_PACKAGE}"
$( cd $MANAGARM_BUILD_DIR; xbstrap pull-pack --deps-of ${MANAGARM_META_PACKAGE} mlibc mlibc-headers )
echo "auto-create-env: downloading needed tool archives"
$( cd $MANAGARM_BUILD_DIR; xbstrap download-tool-archive system-gcc cross-binutils host-limine )
echo "auto-create-env: installing meta-package ${MANAGARM_META_PACKAGE}"
$( cd $MANAGARM_BUILD_DIR; xbstrap install --deps-of ${MANAGARM_META_PACKAGE} )
echo "auto-create-env: finishing image setup"
$( cd $MANAGARM_BUILD_DIR; xbstrap run initialize-empty-image )
echo "auto-create-env: done! enter the build folder and run xbstrap run make-image to finish creating the image and xbstrap run qemu to run your new managarm image in a VM!"

