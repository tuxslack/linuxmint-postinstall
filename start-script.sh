#!/usr/bin/env bash

wget https://github.com/thiagoneo/lmde-postinstall/archive/refs/tags/2023-01-09.tar.gz
tar -xzvf 2023-01-09.tar.gz
cd lmde-postinstall-2023-01-09/
chmod +x *.sh

bash script.sh
