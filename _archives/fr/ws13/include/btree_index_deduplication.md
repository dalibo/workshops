<!--
Les commits sur ce sujet sont :

| Sujet              | Lien                                                                                                        |
|====================|=============================================================================================================|
| infra (operator = exists) | https://git.postgresql.org/gitweb/?p=postgresql.git;a=commit;h=612a1ab76724aa1514b6509269342649f8cab375 |
|  Add dedup to nbtree | https://git.postgresql.org/gitweb/?p=postgresql.git;a=commit;h=0d861bbb702f8aa05c2a4e3f1650e7e8df8c8c27 |
| pageinspect  | https://git.postgresql.org/gitweb/?p=postgresql.git;a=commit;h=93ee38eade1b2b4964354b95b01b09e17d6f098d |
| no dedup for unique index | https://git.postgresql.org/gitweb/?p=postgresql.git;a=commit;h=5da8bf8bbb5c119d4bd767dbdfaf10efd348c0fd |

Discussion : https://www.postgresql.org/docs/devel/btree-implementation.html#BTREE-DEDUPLICATION
-->


#### Objectifs

<div class="slide-content">

* Réduction du volume d'un index en ne stockant qu'une seule fois chaque valeur
* Gain en espace disque et en performance en lecture
* Implémentation paresseuse : pas de perte de performance en écriture

</div>

<div class="notes"> 

Un index est une structure de données permettant de retrouver rapidement les
données. L'utilisation d'un index simplifie et accélère les opérations de
recherche, de tri, de jointure ou d'agrégation. La structure par défaut pour
les index dans PostgreSQL est le *btree*, pour *balanced tree*.

Lorsque la colonne d'une table est indexée, pour chaque ligne de la table, un
élément sera inséré dans la structure *btree*. Cette structure, dans
PostgreSQL, est stockée physiquement dans des pages de 8 Ko par défaut.

La version 13 vient modifier ce comportement. Il est en effet possible pour
l'index de ne stocker qu'une seule fois la valeur pour de multiples lignes.

Cette opération de déduplication fonctionne de façon paresseuse. La
vérification d'une valeur déjà stockée dans l'index et identique ne sera pas
effectuée à chaque insertion. Lorsqu'une page d'un index est totalement
remplie, l'ajout d'un nouvel élément déclenchera une opération de fusion.

</div>

-----

#### Nouveaux éléments

<div class="slide-content">

* Nouvelles colonnes visibles avec l'extension *pageinspect*
* Champ *allequalimage* dans `bt_metap()`
  * si *true* : possibilité de déduplication
* Champs *htid* et *tids* dans `bt_page_items()`
  * utilisés pour stocker tous les tuples indexés pour une valeur donnée

</div>

<div class="notes">

Prenons par exemple la table et l'index suivant :

```
CREATE TABLE t_dedup (i int);
CREATE INDEX t_dedup_i_idx ON t_dedup (i);
INSERT INTO t_dedup (i) SELECT g % 2 FROM generate_series(1, 4) g;
CREATE EXTENSION pageinspect;
```

Nous allons vérifier la structure interne de l'objet :

```
pg13=# SELECT itemoffset,ctid,itemlen,data,htid,tids 
       FROM bt_page_items('t_dedup_i_idx', 1);
 itemoffset | ctid  | itemlen |          data           | htid  | tids 
------------+-------+---------+-------------------------+-------+------
          1 | (0,2) |      16 | 00 00 00 00 00 00 00 00 | (0,2) | 
          2 | (0,4) |      16 | 00 00 00 00 00 00 00 00 | (0,4) | 
          3 | (0,1) |      16 | 01 00 00 00 00 00 00 00 | (0,1) | 
          4 | (0,3) |      16 | 01 00 00 00 00 00 00 00 | (0,3) | 
```

Pour les 4 lignes les valeurs 0 et 1, visible dans le champ *data* sont
dupliquées.

Continuons d'insérer des données jusqu'à remplir la page d'index :

```
pg13=# INSERT INTO t_dedup (i) SELECT g % 2 FROM generate_series(1, 403) g;
INSERT 0 403
pg13=# SELECT count(*) FROM bt_page_items ('t_dedup_i_idx', 1);

 count 
-------
   407
(1 ligne)
```

Insérons un nouvel élément dans la table :

```
thibaut=# INSERT INTO t_dedup (i) SELECT 0;
INSERT 0 1
thibaut=# SELECT count(*) FROM bt_page_items('t_dedup_i_idx', 1);
 count 
-------
     3
(1 ligne)
```

Le remplissage de la page d'index a déclenché une opération de fusion en dédupliquant
les lignes :

```
pg13=# SELECT itemoffset,ctid,itemlen,data,htid,tids 
       FROM bt_page_items('t_dedup_i_idx', 1);
-[ RECORD 1 ]-------------------------------------------------------------------
itemoffset | 1
ctid       | (16,8395)
itemlen    | 1240
data       | 00 00 00 00 00 00 00 00
htid       | (0,2)
tids       | {"(0,2)","(0,4)","(0,6)","(0,8)","(0,10)","(0,12)","(0,14)",
           | (...)
		   | "(1,170)","(1,172)","(1,174)","(1,176)","(1,178)","(1,180)"}
-[ RECORD 2 ]-------------------------------------------------------------------
itemoffset | 2
ctid       | (1,182)
itemlen    | 16
data       | 00 00 00 00 00 00 00 00
htid       | (1,182)
tids       | 
-[ RECORD 3 ]-------------------------------------------------------------------
itemoffset | 3
ctid       | (16,8396)
itemlen    | 1240
data       | 01 00 00 00 00 00 00 00
htid       | (0,1)
tids       | {"(0,1)","(0,3)","(0,5)","(0,7)","(0,9)","(0,11)","(0,13)",
           |  (...)
		   | "(1,171)","(1,173)","(1,175)","(1,177)","(1,179)","(1,181)"}
```

L'opération de déduplication est également déclenchée lors d'un REINDEX ainsi
qu'à la création de l'index.

Cette fonctionnalité permet tout d'abord, suivant la redondance des données
indexées, un gain de place non négligeable. Cette moindre volumétrie permet des
gains de performance en lecture et en écriture.  
D'autre part, la déduplication peut diminuer la fragmentation des index, y
compris pour des index uniques, du fait de l'indexation des anciennes versions des lignes.

Il peut exister des cas très rares pour lesquels cette nouvelle fonctionnalité
entraînera des baisses de performances. Par exemple, pour certaines données
quasi uniques, le moteur va passer du temps à essayer de dédupliquer les lignes
pour un gain d'espace négligeable. En cas de souci de performance, on pourra
choisir de désactiver la déduplication :


```
CREATE INDEX t_i_no_dedup_idx ON t (i) WITH (deduplicate_items = off);
```

</div>

-----

#### Limitation

<div class="slide-content">

* Déduplication non disponible pour plusieurs types de colonnes :

   * les types `text`, `varchar` et `char` si une collation non-déterministe
     est utilisée
   * le type `numeric` et par extension les types `float4`, `float8` et `jsonb`
   * les types composites, tableau et intervalle
   * les index couvrants (mot clé `INCLUDE`)

</div>

<div class="notes">

</div>
