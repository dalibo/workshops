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

La notion de _Heap Only Tuple_ (HOT) a été mis en place pour palier ce problème.
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
après 1,5 millions de transactions en version 13 et 14.
Rappelons que `pgbench` consiste essentiellement à mettre à jour les lignes
d'une base, sans en ajouter ou supprimer.
Les index par défaut étant des clés primaires
ou étrangères, on ajoute aussi un index sur des valeurs qui changent réellement.
Pour un test aussi court, on désactive l'autovacuum :
<!--  si l autovacuum passe, il nettoie trop vite les index pour avoir un  bel effet -->

```bash
createdb bench
pgbench -i -s 100 bench --unlogged-tables
psql -X -d bench -c 'CREATE INDEX ON pgbench_accounts (abalance) ' -c '\di+'
psql -X -d bench -c 'ALTER TABLE pgbench_accounts SET (autovacuum_enabled = off)'
psql -X -d bench -c 'ALTER TABLE pgbench_history SET (autovacuum_enabled = off)'
pgbench -n -c 50 -t30000  bench -r -P10
psql -c '\di+' bench
```

<!--- 

v13 avant :
 Schéma |              Nom              | Type  | Propriétaire |      Table       | Persistence | Méthode d'accès | Taille | Description 
--------+-------------------------------+-------+--------------+------------------+-------------+-----------------+--------+-------------
 public | pgbench_accounts_abalance_idx | index | pgbench      | pgbench_accounts | permanent   | btree           | 66 MB  | 
 public | pgbench_accounts_pkey         | index | pgbench      | pgbench_accounts | permanent   | btree           | 214 MB | 
 public | pgbench_branches_pkey         | index | pgbench      | pgbench_branches | permanent   | btree           | 16 kB  | 
 public | pgbench_tellers_pkey          | index | pgbench      | pgbench_tellers  | permanent   | btree           | 40 kB  | 

apres

 Schéma |              Nom              | Type  | Propriétaire |      Table       |  Persistence   | Méthode d'accès | Taille | Description 
--------+-------------------------------+-------+--------------+------------------+----------------+-----------------+--------+-------------
 public | pgbench_accounts_abalance_idx | index | postgres     | pgbench_accounts | non journalisé | btree           | 80 MB  | 
 public | pgbench_accounts_pkey         | index | postgres     | pgbench_accounts | non journalisé | btree           | 333 MB | 
 public | pgbench_branches_pkey         | index | postgres     | pgbench_branches | non journalisé | btree           | 24 kB  | 
 public | pgbench_tellers_pkey          | index | postgres     | pgbench_tellers  | non journalisé | btree           | 64 kB  | 
(4 lignes)

 
v14  avant

Schéma |              Nom              | Type  | Propriétaire |      Table       | Persistence | Méthode d'accès | Taille | Description 
--------+-------------------------------+-------+--------------+------------------+-------------+-----------------+--------+-------------
 public | pgbench_accounts_abalance_idx | index | pgbench      | pgbench_accounts | permanent   | btree           | 66 MB  | 
 public | pgbench_accounts_pkey         | index | pgbench      | pgbench_accounts | permanent   | btree           | 214 MB | 
 public | pgbench_branches_pkey         | index | pgbench      | pgbench_branches | permanent   | btree           | 16 kB  | 
 public | pgbench_tellers_pkey          | index | pgbench      | pgbench_tellers  | permanent   | btree           | 40 kB  | 

 
apres 

 Schéma |              Nom              | Type  | Propriétaire |      Table       |  Persistence   | Méthode d'accès | Taille | Description 
--------+-------------------------------+-------+--------------+------------------+----------------+-----------------+--------+-------------
 public | pgbench_accounts_abalance_idx | index | postgres     | pgbench_accounts | non journalisé | btree           | 79 MB  | 
 public | pgbench_accounts_pkey         | index | postgres     | pgbench_accounts | non journalisé | btree           | 214 MB | 
 public | pgbench_branches_pkey         | index | postgres     | pgbench_branches | non journalisé | btree           | 24 kB  | 
 public | pgbench_tellers_pkey          | index | postgres     | pgbench_tellers  | non journalisé | btree           | 64 kB  | 

--->

Le résultat montre que les index ont moins grossi en version 14 :

|         Name                   |  Taille avant | Taille après (v13)| Taille après (v14)|
|--------------------------------|---------------|-------------------|-------------------|
| pgbench_accounts_abalance_idx  |       66 Mo   |           80 Mo   |           79 MB   |
| pgbench_accounts_pkey          |      214 Mo   |          333 Mo   |          214 MB   |
| pgbench_branches_pkey          |       16 ko   |           56 ko   |           40 kB   |
| pgbench_tellers_pkey           |       40 ko   |          224 ko   |          144 kB   |

Dans la réalité, l'autovacuum fonctionnera et nettoiera une partie des lignes au fil de l'eau,
mais il peut être gêné par les autres transactions en cours.
PostgreSQL 14 permettra donc d'éviter quelques `REINDEX`.

Les commits sur ce sujet sont :

* [Enhance nbtree index tuple deletion](https://git.postgresql.org/gitweb/?p=postgresql.git;a=commit;h=d168b666823b6e0bcf60ed19ce24fb5fb91b8ccf)
* [Pass down "logically unchanged index" hint](https://git.postgresql.org/gitweb/?p=postgresql.git;a=commit;h=9dc718bd)
* [Discussion](https://www.postgresql.org/message-id/flat/CAH2-Wzm+maE3apHB8NOtmM=p-DO65j2V5GzAWCOEEuy3JZgb2g@mail.gmail.com)

</div>

