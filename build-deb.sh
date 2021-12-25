#!/bin/bash
#
# Build & install mcpelauncher-thesonicmaster from latest sources.
# For more information about mcpelauncher-thesonicmaster, see
# https://mcpelauncher-thesonicmaster.sourceforge.io
#
# This script will create a DEB package for Debian based distros.
#
# Copyright (C) 2021 The Sonic Master
#
# This program is free software: you can redistribute it and/or modify it under
# the terms of the GNU General Public License as published by the Free Software
# Foundation, either version 3 of the License, or (at your option) any later
# version.
#
# This program is distributed in the hope that it will be useful, but WITHOUT
# ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
# FOR A PARTICULAR PURPOSE. See the GNU General Public License for more
# details.
#
# You should have received a copy of the GNU General Public License along with
# this program. If not, see <https://www.gnu.org/licenses/>.
#
# Exit on error.
set -e
# Print status messages in colour and in bold.
status() {
  echo -e "\e[1m\e[32m$*\e[0m"
}
status2() {
  printf "\e[1m\e[32m$*\e[0m"
}
warn() {
  echo -e "\e[1m\e[33m$*\e[0m"
}
# Initial status message.
status "==> Build DEB script for mcpelauncher to fix license error."
status "==> Copyright (c) 2021 The Sonic Master."
sleep 1
echo
# Display a warning if running as root, but don't stop the script.
if [ $EUID = 0 ]; then
  warn "==> WARNING: While no cats have been harmed, this script may contain"
  warn "==> bugs that could damage your system. Therefore, running as root is"
  warn "==> strongly discouraged. The Sonic Master assumes no responsiblity"
  warn "==> for any damage to your system as a result of usage of this script."
  sleep 3
  echo
  warn "==> Press CTRL+C to cancel, or the script will proceed in 10s..."
  sleep 10
  echo
fi
# Save the current directory so we know where to put the finished DEB package.
savedir="$(pwd)"
# Change to a clean build directory.
builddir=$(mktemp -d)
cd $builddir
# Set package directory.
pkgdir=$(mktemp -d)/mcpelauncher-thesonicmaster
# Ensure we are compiling with Clang(gcc). For Clang need lld
export CC=clang CXX=clang++
# Set compiler flags, but don't override existing flags.
if [ -z "$CFLAGS" ]; then
  # Optimise for size (-Os)
  #export CFLAGS="-Os"
  export CFLAGS="-Os -m32"
fi
if [ -z "$CXXFLAGS" ]; then
  # Optimise for size (-Os)
  #export CXXFLAGS="-Os"
  export CXXFLAGS="-Os -m32"
fi
# Check and set version version
status2 "==> Checking version... "
ver="$(curl -Ls https://downloads.sourceforge.net/mcpelauncher-thesonicmaster/latest.version)"
pkgver="$ver~$(lsb_release -sc | sed 's/\///')"
status "$ver"
# Download latest source code.
status "==> Downloading source code..."
curl -LO https://downloads.sourceforge.net/mcpelauncher-thesonicmaster/sources/mcpelauncher-thesonicmaster-$ver.tar.xz
# Verify source sha256sum.
status2 "==> Verifying source against sha256sum... "
curl -Ls https://downloads.sourceforge.net/mcpelauncher-thesonicmaster/sources/mcpelauncher-thesonicmaster-$ver.tar.xz.sha256 | sha256sum -c > /dev/null
status "All Good!"
# Extract source tarball.
status "==> Unpacking source tarball, please be patient..."
tar -xJf mcpelauncher-thesonicmaster-$ver.tar.xz
# Remove tarball to free up space.
rm mcpelauncher-thesonicmaster-$ver.tar.xz
# Change to source directory.
cd mcpelauncher-thesonicmaster-$ver
# Specify cmake options for the build.
#cmake_options="-DCMAKE_INSTALL_PREFIX=/usr -DCMAKE_BUILD_TYPE=Release -Wno-dev -G Ninja -DCMAKE_CXX_FLAGS=-m32 -DCMAKE_CFLAGS=-m32"
cmake_options="-DCMAKE_INSTALL_PREFIX=/usr -DCMAKE_BUILD_TYPE=Release -Wno-dev -G Ninja -LINK_FLAGS=-m32"
# Build MSA.
status "==> Building MSA (for Xbox Live)..."
cd msa
mkdir build && cd build
cmake -DENABLE_MSA_QT_UI=ON $cmake_options ..
ninja
# Install MSA.
status "==> Installing MSA..."
DESTDIR=$pkgdir ninja install
cd ../..
# Build the game launcher.
status "==> Building the game launcher..."
cd mcpelauncher
mkdir build && cd build
cmake -DENABLE_QT_ERROR_UI=OFF -DJNI_USE_JNIVM=ON $cmake_options ..
ninja
# Install the game launcher.
status "==> Installing the game launcher..."
DESTDIR=$pkgdir ninja install
cd ../..
# Build the Qt GUI.
status "==> Building the Qt GUI..."
cd mcpelauncher-ui
mkdir build && cd build
cmake -DLAUNCHER_VERSION_CODE="DEB" $cmake_options ..
ninja
# Install the Qt GUI.
status "==> Installing the Qt GUI..."
DESTDIR=$pkgdir ninja install
# Strip unneeded debugging symbols to free up space.
status "==> Stripping executables..."
cd $pkgdir/usr/bin
strip --strip-all *
# Collect maintainer information (required for the Debian control file).
status "==> Collecting maintainer information for the package..."
warn "==> Note: If running non-interactively, export NAME and EMAIL as needed."
mkdir -p $pkgdir/DEBIAN
while [ -z "$NAME" ]; do
  read -p "Your full name (or name of organisation): " NAME
done
while [ -z "$EMAIL" ]; do
  read -p "Email address: " EMAIL
done
# Collect other package info needed for the control file.
status "==> Collecting system/software info for the package..."
# Set correct architecture (only x86 and x86_64 currently supported).
arch=$(dpkg --print-architecture)
#arch=i386 # Force i386 arch
# Set correct dependencies for the package.
case $arch in
  amd64) libdir=/usr/lib/x86_64-linux-gnu ;;
  i386) libdir=/usr/lib/i386-linux-gnu ;;
  arm64) libdir=/usr/lib/aarch64-linux-gnu ;;
  armhf) libdir=/usr/lib/arm-linux-gnueabihf ;;
  armel) libdir=/usr/lib/arm-linux-gnueabi ;;
esac
if [ -f $libdir/libzip.so.4 ]; then
  libzip=libzip4
elif [ -f $libdir/libzip.so.5 ]; then
  libzip=libzip5
else
  warn "==> Correct libzip version not found. Dependency will be excluded."
fi
if [ -f $libdir/libprotobuf.so.10 ]; then
  protobuf=libprotobuf10
elif [ -f $libdir/libprotobuf.so.17 ]; then
  protobuf=libprotobuf17
elif [ -f $libdir/libprotobuf.so.23 ]; then
  protobuf=libprotobuf23
elif [ -f $libdir/libprotobuf.so.26 ]; then
  protobuf=libprotobuf26
else
  warn "==> Correct protobuf version not found. Dependency will be excluded."
fi
# Calculate package size.
cd $pkgdir
size=$(du -k usr | tail -n1 | sed 's/usr//')
# Write Debian control file (metadata of the package).
status "==> Writing control file..."
cat > $pkgdir/DEBIAN/control << END
Package: mcpelauncher-thesonicmaster
Version: $pkgver
Architecture: $arch
Depends: libc6, libssl1.1, libcurl4, libqt5widgets5, libqt5webenginewidgets5, libstdc++6, libx11-6, zlib1g, libpng16-16, libevdev2, libudev1, $libzip, libuv1, libqt5quick5, libqt5svg5, libqt5quickcontrols2-5, libqt5quicktemplates2-5, libqt5concurrent5, $protobuf, qml-module-qtquick2, qml-module-qtquick-layouts, qml-module-qtquick-controls, qml-module-qtquick-controls2, qml-module-qtquick-window2, qml-module-qtquick-dialogs, qml-module-qtwebengine, qml-module-qt-labs-settings, qml-module-qt-labs-folderlistmodel
Conflicts: msa-daemon, msa-ui-qt, mcpelauncher-client, mcpelauncher-ui-qt
Maintainer: $NAME <$EMAIL>
Installed-Size: $size
Section: custom
Priority: optional
Homepage: https://mcpelauncher-thesonicmaster.sourceforge.io
Description: Minecraft Bedrock Edition Linux launcher with license error fixed.
END
# Remove extra commas from control file, if present (needs to be done twice).
sed -i 's/, ,/,/' $pkgdir/DEBIAN/control
sed -i 's/, ,/,/' $pkgdir/DEBIAN/control
# Create package.
status "==> Building DEB package..."
cd $pkgdir/..
dpkg-deb --build mcpelauncher-thesonicmaster mcpelauncher-thesonicmaster_${pkgver}_${arch}.deb
mv mcpelauncher-thesonicmaster_${pkgver}_${arch}.deb "$savedir"
# Clean up.
status "==> Cleaning up..."
rm -rf $builddir $pkgdir
status "==> Debian package successfully created."
