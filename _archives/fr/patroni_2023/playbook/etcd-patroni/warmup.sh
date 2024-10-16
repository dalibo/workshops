#! /bin/bash

set -x

sudo lxc-create -n warmup -t debian -- -r buster
sudo lxc-destroy warmup
