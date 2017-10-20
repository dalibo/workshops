QUICKSTART
===============================================================================

Installing the full pandoc compilation stack is long and complex. Before doing
it, you can try it easly with our [pandoc docker image](https://hub.docker.com/r/dalibo/pandocker/) ! 

1. Install docker : https://docs.docker.com/engine/installation/

2. Launch `DOCKER=latest make all`


If you want to use it permanently you can add an alias to your `~/.bashrc` file:

```sh
alias pandoc="docker run --volume ~/.dalibo:/root/.dalibo --volume \`pwd\`:/pandoc dalibo/pandocker $@"
```
