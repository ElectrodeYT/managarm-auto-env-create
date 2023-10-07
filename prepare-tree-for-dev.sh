#!/bin/bash
set -e

MANAGARM_BASE_DIR=$(pwd)/managarm

while getopts 'd:p:h' opt; do
  case "$opt" in
  d)
    MANAGARM_BASE_DIR=$(pwd)/${OPTARG}
    ;;
  p)
    MANAGARM_META_PACKAGE=${OPTARG}
    ;;
  h)
    echo "Usage: $(basename $0) [-d managarm_base_dir]"
    echo "By default, assume the tree is called \"managarm\"."
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

echo -e "Downloading needed tools for tree ${MANAGARM_BASE_DIR}"


MANAGARM_BUILD_DIR=$MANAGARM_BASE_DIR/build
MANAGARM_SRC_DIR=$MANAGARM_BASE_DIR/src
MANAGARM_ROOTFS_PATH=$MANAGARM_BASE_DIR/rootfs

( cd $MANAGARM_BUILD_DIR; xbstrap download-tool-archive bootstrap-system-gcc system-gcc kernel-gcc host-managarm-tools host-libtool host-automake-v1.11 host-automake-v1.15 host-llvm-toolchain host-cmake host-pkg-config host-protoc )

