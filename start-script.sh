#!/usr/bin/env bash

wget https://github.com/thiagoneo/lmde-postinstall/archive/refs/tags/testing-2.tar.gz
tar -xzvf testing-2.tar.gz
cd lmde-postinstall-testing-2/
chmod +x *.sh

bash script.sh
