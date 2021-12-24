
#!/bin/bash
#
# Install mcpelauncher build dependencies for Debian systems.
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
# Exit on error
set -e
# Function to find the best way of getting root.
as_root() {
  if [ $EUID = 0 ]; then
    $*
  elif [ -x /usr/bin/sudo ]; then
    sudo $*
  elif [ -x /usr/local/bin/sudo ]; then
    sudo $*
  else
    su -c "$*"
  fi
}
# Launch apt to install dependencies.
# For amd64 first run - dpkg --add-architecture i386 && apt update
as_root apt install -y build-essential clang cmake gettext:i386 git \
                       libasound2:i386 libcurl4-openssl-dev:i386 libegl1-mesa-dev:i386 \
                       libevdev-dev:i386 libpng-dev:i386 libprotobuf-dev:i386 libpulse-dev:i386 \
                       libqt5svg5-dev:i386 libssl-dev:i386 libtool:i386 libudev-dev:i386 \
                       libuv1-dev:i386 libx11-dev:i386 libxi-dev:i386 libzip-dev:i386 ninja-build:i386 \
                       protobuf-compiler:i386 qml-module-qtquick2:i386 \
                       qml-module-qtquick-controls:i386 \
                       qml-module-qtquick-controls2:i386 qml-module-qtquick-dialogs:i386 \
                       qml-module-qtquick-layouts:i386 qml-module-qtquick-window2:i386 \
                       qml-module-qt-labs-folderlistmodel:i386 \
                       qml-module-qt-labs-settings:i386 qtbase5-dev:i386 \
                       qtdeclarative5-dev:i386 qttools5-dev:i386 qttools5-dev-tools:i386 \
                       qtwebengine5-dev:i386 texinfo:i386
