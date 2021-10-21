<!--
Les commits sur ce sujet sont :

| Sujet                    | Lien                                                                                                        |
|==========================|=============================================================================================================|
| vacuumdb parallélisé  | https://git.postgresql.org/gitweb/?p=postgresql.git;a=commitdiff;h=47bc9ced0d0e96523e2c639c7066c9aede189ed7 |

-->

<!-- #### Parallélisation de vacuumdb -->

<div class="slide-content">

  * Nouvelle option `--parallel` (`-P`)
  * Utilisé pour la nouvelle clause PARALLEL de VACUUM
  * À ne pas confondre avec l'option `--jobs`

</div>

<div class="notes">

L'outil `vacuumdb` dispose de l'option `-P` (ou `--parallel` en version
longue). La valeur de cette option est utilisée pour la clause `PARALLEL` de
la commande `VACUUM`. Il s'agit donc de paralléliser le traitement des index
pour les tables disposant d'au moins deux index.

En voici un exemple :

```
$ vacuumdb --parallel 2 --table t1 -e postgres 2>&1 | grep VACUUM
VACUUM (PARALLEL 2) public.t1;
```

Ce nouvel argument n'est pas à confondre avec `--jobs` qui existait déjà.
L'argument `--jobs` lance plusieurs connexions au serveur PostgreSQL pour
exécuter plusieurs `VACUUM` sur plusieurs objets différents en même temps.

</div>
