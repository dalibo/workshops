<!--
Les commits sur ce sujet sont :

* https://git.postgresql.org/gitweb/?p=postgresql.git;a=commit;h=8ff1c94649f5c9184ac5f07981d8aea9dfd7ac19

Discussion

* https://gitlab.dalibo.info/formation/workshops/-/issues/116

-->

<div class="slide-content">

* Ajout d'une routine dans l'API Foreign Data Wrapper pour la commande `TRUNCATE`
* Supportée pour les serveurs distants PostgreSQL avec l'extension `postgres_fdw`
* Valable pour les partitions distantes d'une table partitionnée
* Option `truncatable` activée par défaut

</div>

<div class="notes">

La commande `TRUNCATE` dispose à présent d'un `callback` dans l'API _Foreign
Data Wrapper_. L'extension `postgres_fwd` propose une implémentation pour les 
serveurs distants PostgreSQL avec l'ensemble des options existantes pour cette 
commande :

* `CASCADE` : supprime automatiquement les lignes des tables disposant d'une 
  contrainte de clé étrangère sur la table concernée ;
* `RESTRICT` : refuse le vidage de la table si l'une de ses colonnes est impliquée
  dans une contrainte de clé étrangère (comportement par défaut) ;
* `RESTART IDENTITY` : redémarre les séquences rattachés aux colonnes d'identité 
  de la table tronquée ; 
* `CONTINUE IDENTITY` : ne change pas la valeur des séquences (comportement par
  défaut).

L'usage du `TRUNCATE` apporte un gain de performance par rapport à la commande
`DELETE`, qui était jusqu'à présent la seule alternative pour vider les tables 
distantes. La commande `TRUNCATE` sur une table partitionnée est également
propagée vers les différents serveurs distants pour réaliser le vidage des partitions
distantes.

Ce nouveau comportement peut être désactivé par l'option `truncatable` au niveau
de la table ou du serveur distant.

```sql
ALTER SERVER srv1 OPTIONS (ADD truncatable 'false');
ALTER FOREIGN TABLE tbl1 OPTIONS (ADD truncatable 'false');

TRUNCATE tbl1;
```
```text
ERROR:  foreign table "tbl1" does not allow truncates
```

</div>
