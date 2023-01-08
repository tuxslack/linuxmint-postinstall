#!/usr/bin/env bash

wget https://github.com/thiagoneo/lmde-postinstall/archive/refs/tags/testing-1.tar.gz
tar -xzvf testing-1.tar.gz
cd lmde-postinstall-testing-1/
chmod +x *.sh

bash script.sh
