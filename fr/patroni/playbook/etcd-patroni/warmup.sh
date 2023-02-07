#! /bin/bash

# Ce script permet de récupérer l'image Debian de base pour
# accélérer la création des conteneurs LXC suivants.

set -x

sudo lxc-create -n warmup -t debian -- -r buster
sudo lxc-destroy warmup
