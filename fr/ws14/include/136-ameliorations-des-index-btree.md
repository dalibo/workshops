<!--
Les commits sur ce sujet sont :

* https://git.postgresql.org/gitweb/?p=postgresql.git;a=commit;h=d168b666823b6e0bcf60ed19ce24fb5fb91b8ccf
* https://git.postgresql.org/gitweb/?p=postgresql.git;a=commit;h=9dc718bd

Discussion

* https://www.postgresql.org/message-id/flat/CAH2-Wzm+maE3apHB8NOtmM=p-DO65j2V5GzAWCOEEuy3JZgb2g@mail.gmail.com
-->

<div class="slide-content">

* Nettoyage des index B-tree « par le haut »
  * limite la fragmentation lorsque des lignes sont fréquemment modifiées

</div>

<div class="notes">

Lorsqu'une ligne est mise à jour par un ordre `UPDATE`, PostgreSQL garde
l'ancienne version de la ligne dans la table jusqu'à ce qu'elle ne soit plus
nécessaire à aucune transaction. L'adresse physique de chaque version est
différente. Il faut donc ajouter cette nouvelle version à tous les index (y
compris ceux pour lesquels la donnée n'a pas changé), afin de s'assurer qu'elle
soit visible lors des parcours d'index. Ce processus est très pénalisant pour
les performances et peut provoquer de la fragmentation.

La notion de `Heap Only Tuple` (_HOT_) a été mis en place pour palier ce problème.
Lorsqu'une mise à jour ne touche aucune colonne indexée et que la nouvelle
version de ligne peut être stockée dans la même page que les autres versions,
PostgreSQL peut éviter la mise à jour des index.

Il y a cependant beaucoup de cas où il n'est pas possible d'éviter la mise à
jour de colonnes indexées. Dans certains profils d'activité avec beaucoup de
mise à jour, cela peut mener à la création de beaucoup d'enregistrements d'index
correspondant à des versions différentes d'une même ligne dans la table, mais
pour lequel l'enregistrement dans l'index est identique.

PostgreSQL 14 introduit un nouveau mécanisme pour limiter fortement la
fragmentation due à des changements de versions fréquents d'une ligne de la
table sans changement des données dans l'index. Lorsque ce genre de
modifications se produit, l'exécuteur marque les tuples avec le hint
_logically unchanged index_. Par la suite, lorsqu'une page menace de se diviser
(_page split_), PostgreSQL déclenche un nettoyage des doublons de ce genre
correspondant à des lignes mortes. Ce nettoyage est décrit comme _bottom up_
(du bas vers le haut) car c'est la requête qui le déclenche lorsque la page va
se remplir. Il se distingue du nettoyage qualifié de _top down_ (de haut en
bas) effectué par l'autovacuum.

Un autre mécanisme se déclenche en prévention
d'une division de page : la suppression des entrées d'index marquées comme
mortes lors d'_index scan_ précédents (avec le flag `LP_DEAD`). Cette dernière
est qualifiée de _simple index tuple deletion_ (suppression simple de tuple
d'index).

Si les nettoyages _top down_ et _simple_ ne suffisent pas, la déduplication tente
de faire de la place dans la page. En dernier recours, la page se divise en
deux (_page split_) ce qui fait grossir l'index.

Pour le tester, on peut comparer la taille des index sur une base `pgbench`
après 10 minutes d'activité, en version 13 et 14 :

<!-- FIXME   pgbench mauvais exemple même en laissant tourner plus longtemps ;
il faudrait des insertions et suppressions d'ID en cascade
-->

```bash
createdb bench
pgbench -i -s 100 bench
pgbench -n -c 90 -T 600 bench
```

Le résultat montre que les index ont moins grossi en version 14.

| Schema |         Name          |  Taille avant | Taille après v13  |  Taille après v14  |
|--------|-----------------------|---------------|-------------------|--------------------|
| public | pgbench_accounts_pkey | 214 MB        | 214 MB            | 214 MB             |
| public | pgbench_branches_pkey | 16 kB         | 56 kB             | 40 kB              |
| public | pgbench_tellers_pkey  | 40 kB         | 224 kB            | 144 kB             |

</div>
