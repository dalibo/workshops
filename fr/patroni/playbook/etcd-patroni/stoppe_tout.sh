#!/bin/bash
set -x
for i in pg-2 pg-3 pg-1 e1 e2 e3 backup ; do sudo lxc-stop $i ; done
