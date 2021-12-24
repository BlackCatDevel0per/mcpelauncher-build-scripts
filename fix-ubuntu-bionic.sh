sudo apt remove --autoremove clang
sudo apt install clang-10
sudo ln -sf clang-10 /usr/bin/clang
sudo ln -sf clang++-10 /usr/bin/clang++

sudo apt remove --autoremove cmake
curl -LOs https://github.com/Kitware/CMake/releases/download/v3.20.5/cmake-3.20.5-linux-x86_64.tar.gz
sudo tar --no-same-owner -xf cmake-3.20.5-linux-x86_64.tar.gz -C /usr/local --strip-components=1
rm cmake-3.20.5-linux-x86_64.tar.gz

sudo apt install qt5-default
