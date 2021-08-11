<!--
Les commits sur ce sujet sont :

| Sujet                    | Lien                                                                                                        |
|==========================|=============================================================================================================|
| reindexdb parallélisé | https://git.postgresql.org/gitweb/?p=postgresql.git;a=commitdiff;h=5ab892c391c6bc54a00e7a8de5cab077cabace6a |

-->

<!-- #### Parallélisation de reindexdb -->

<div class="slide-content">

  * Nouvelle option `--jobs` (`-j`) pour reindexdb
  * Lance autant de connexions sur le serveur PostgreSQL
  * Exécute un REINDEX par connexion
  * Incompatible avec les options SYSTEM et INDEX

</div>

<div class="notes">

L'outil `reindexdb` dispose enfin de l'option `-j` (`--jobs` en version
longue).

L'outil lance un certain nombre de connexions au serveur de bases de données,
ce nombre dépendant de la valeur de l'option en ligne de commande. Chaque
connexion se voit dédier un index à réindexer. De ce fait, l'option
`--index`, qui permet de réindexer un seul index, n'est pas compatible avec
l'option `-j`.

Rappelons que la (ré)indexation est parallélisée depuis PostgreSQL 11
(paramètre `max_parallel_maintenance_workers`), et qu'un `REINDEX` peut donc
déjà utiliser plusieurs processeurs.

De même, l'option `--system` permet de réindexer les index systèmes. Or
ceux-ci sont toujours réindexés sur une seule connexion pour éviter un
_deadlock_. L'option `--system` est donc incompatible avec l'option `-j`.
Elle n'a pas de sens si on demande à ne réindexer qu'un index (`--index`).


</div>
