<!--
Les sources pour ce sujet sont :

* https://git.postgresql.org/gitweb/?p=postgresql.git;a=commit;h=0da243fed0875932f781aff08df782b56af58d02
* https://git.postgresql.org/gitweb/?p=postgresql.git;a=commit;h=84adc8e20f54e93a003cd316fa1eb9b03e393288

Discussion :

* https://postgr.es/m/20230224191840.GD1653@telsasoft.com
* https://postgr.es/m/20201221194924.GI30237@telsasoft.com

-->

<div class="slide-content">

  * Deux nouveaux algorithmes de compression supportés par `pg_dump` :
    + `zstd`
    + `lz4`
  * Option `-Z / --compress`

</div>

<div class="notes">

Les algorithmes de compression `zstd` et `lz4` sont désormais supportés par
l'utilitaire `pg_dump`.
Le choix de l'algorithme se fait grâce à l'option `-Z / --compress` de la
commande. Elle peut prendre les valeurs `gzip`, `lz4`, `zstd` ou `none`.

Voici à titre d'exemple trois exports compressés d'une base de 19Go ainsi que le
temps d'exécution nécessaire pour les obtenir.

```bash
# gzip
$ time pg_dump -U postgres -h 127.0.0.1 > /tmp/gzip.pgdump
real	0m52,381s
user	0m50,106s
sys	  0m2,108s

# lz4
$ time pg_dump -U postgres -Z lz4 -h 127.0.0.1 > /tmp/lz4.pgdump
real	0m47,370s
user	0m13,372s
sys	  0m5,894s

# zstd
$ time pg_dump -U postgres -Z zstd -h 127.0.0.1 > /tmp/zstd.pgdump
real	0m48,629s
user	0m15,789s
sys	0m4,957s

# tailles
$ ls -hl /tmp/*.pgdump
-rw-rw-r-- 1 dalibo dalibo 406M sept. 11 16:37 /tmp/gzip.pgdump
-rw-rw-r-- 1 dalibo dalibo 743M sept. 11 16:38 /tmp/lz4.pgdump
-rw-rw-r-- 1 dalibo dalibo 131M sept. 11 16:39 /tmp/zstd.pgdump
```

Cet exemple nous montre que les exports sont moins volumineux avec l'option `zstd`
et se font plus rapidement avec les options `lz4` et `zstd`.

Des détails pour la compression peuvent être spécifiés. Par exemple, avec un
entier, cela définit le niveau de compression. Le format d'archive `tar` ne
supporte pas du tout la compression.

```bash

$ time pg_dump -U postgres -Z gzip:1 -h 127.0.0.1 > /tmp/gzip1.pgdump
real    0m7,402s

$ time pg_dump -U postgres -Z gzip:6 -h 127.0.0.1 > /tmp/gzip6.pgdump
real    0m10,373s

$ time pg_dump -U postgres -Z gzip:9 -h 127.0.0.1 > /tmp/gzip9.pgdump
real    0m15,967s

$ ls -hl /tmp/gzip*
-rw-rw-r-- 1 dalibo dalibo 83M sept. 28 17:05 /tmp/gzip1.pgdump
-rw-rw-r-- 1 dalibo dalibo 82M sept. 28 17:05 /tmp/gzip6.pgdump
-rw-rw-r-- 1 dalibo dalibo 79M sept. 28 17:05 /tmp/gzip9.pgdump
```

Les tailles et les temps sont purement indicatifs. Les tailles et les durées
seront différentes selon les bases traitées, leurs volumétries,
leurs contenus ou encore le système sous-jacent.

Prendre le temps de choisir l'algorithme de compression est donc essentiel mais
peut apporter de nombreux bénéfices. 

</div>
