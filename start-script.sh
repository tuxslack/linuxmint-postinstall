#!/usr/bin/env bash

wget https://github.com/thiagoneo/lmde-postinstall/archive/refs/tags/current.tar.gz
tar -xzvf current.tar.gz
cd lmde-postinstall-current/
chmod +x *.sh

bash script.sh
