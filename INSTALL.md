INSTALLATION
===============================================================================

**TL;DR** : please read the [QUICKSTART](QUICKSTART.md) first :)


The workshops are written in markdown and compiled in various formats with
[pandoc](https://pandoc.org/). The entire compilation tool chain is based on a
long and strict list of dependencies ( debian, latex, pandoc, etc. ). All
version numbers are set in stone.

_We will only support compilation bugs on this exact tool chain_. You can 
probably make it work on Fedora or Arch Linux but you'll be in uncharted 
territory. 

If you want to keep it simple, you can use our [pandoc docker
image](https://hub.docker.com/r/dalibo/pandocker/) and read the 
[QUICKSTART](QUICKSTART.md) 


Prerequisite
------------------------------------------------------------------------------

Install a Debian Jessie environment.


Install
-----------------------------------------------------------------------------

```shell
URL=https://github.com/jgm/pandoc/releases/download/1.19.2.1/pandoc-1.19.2.1-1-amd64.deb
wget -O pandoc.deb $URL
sudo dpkg --install pandoc.deb
```

Install the latex environment 
-------------------------------------------------------------------------------

**WARNING**: This is huge.

```
apt-get install texlive texlive-xetex 
```


Compile
-------------------------------------------------------------------------------

```
make all
```

