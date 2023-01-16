#!/usr/bin/env bash

wget https://github.com/thiagoneo/lmde-postinstall/archive/refs/tags/2023-01-16-testing.tar.gz
tar -xzvf 2023-01-16-testing.tar.gz
cd lmde-postinstall-2023-01-16-testing/
chmod +x *.sh

bash script.sh
