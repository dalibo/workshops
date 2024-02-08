<!--
Les commits sur ce sujet sont :

* https://git.postgresql.org/gitweb/?p=postgresql.git;a=commit;h=ae4fdde1352fa6b2c9123e91435efafc78c370a0

Discussion

* https://postgr.es/m/CADkLM=ded21M9iZ36hHm-vj2rE2d=zcKpUQMds__Xm2pxLfHKA@mail.gmail.com

-->

<div class="slide-content">

* Indique le nombre de lignes déplacées dans un autre bloc suite à une mise à
  jour
* Ajout d'une colonne pour pg_stat_all_tables
  + `n_tup_newpage_upd`
* Permet d'estimer les bons candidats à la configuration du `fillfactor`

</div>

<div class="notes">

Lors d'un `UPDATE`, PostgreSQL va dupliquer la ligne qui doit être modifiée.
L'ancienne version est simplement indiquée comme morte, la nouvelle est modifiée. 
Cette nouvelle ligne sera enregistrée dans le même bloc que l'ancienne si
l'espace y est suffisant. Sinon elle ira dans un autre bloc, ancien ou nouveau 
suivant la place disponible dans les blocs existants.

Auparavant, il était possible de connaître le nombre de lignes mises à jour ainsi
que le nombre de lignes mises à jour dans le même bloc. Cependant, aucune
colonne n'indiquait le nombre de lignes mises à jour dans un autre bloc. Ceci
arrive en version 16 avec la nouvelle colonne `n_tup_newpage_upd` de la vue
`pg_stat_all_tables`.

L'intérêt est que, si cette colonne augmente fortement, il y a de fortes chances
que la table en question puisse bénéficier d'une configuration à
la baisse du paramètre `fillfactor`.

Par exemple, voici une table de 1000 lignes. Nous désactivons l'autovacuum pour
cette table, histoire qu'il ne nettoie pas la table automatiquement, et nous
nous assurons d'avoir un facteur de remplissage à 100%.

```sql
-- preparation
drop table if exists t1;
create table t1(id integer);
alter table t1 set (autovacuum_enabled=false);
alter table t1 set (fillfactor = 100);
insert into t1 select generate_series(1, 1000);
select n_tup_ins, n_tup_upd, n_tup_hot_upd, n_tup_newpage_upd
  from pg_stat_user_tables
  where relname='t1';

┌───────────┬───────────┬───────────────┬───────────────────┐
│ n_tup_ins │ n_tup_upd │ n_tup_hot_upd │ n_tup_newpage_upd │
├───────────┼───────────┼───────────────┼───────────────────┤
│      1000 │         0 │             0 │                 0 │
└───────────┴───────────┴───────────────┴───────────────────┘
```

Les statistiques indiquent bien les 1000 lignes insérées et aucune ligne mise
à jour.

Faisons un premier `UPDATE` d'une ligne :

```
-- test #1
select ctid from t1 where id=1;

┌───────┐
│ ctid  │
├───────┤
│ (0,1) │
└───────┘

update t1 set id=id where id=1;
select ctid from t1 where id=1;

┌────────┐
│  ctid  │
├────────┤
│ (4,97) │
└────────┘

select n_tup_ins, n_tup_upd, n_tup_hot_upd, n_tup_newpage_upd
  from pg_stat_user_tables
  where relname='t1';

┌───────────┬───────────┬───────────────┬───────────────────┐
│ n_tup_ins │ n_tup_upd │ n_tup_hot_upd │ n_tup_newpage_upd │
├───────────┼───────────┼───────────────┼───────────────────┤
│      1000 │         1 │             0 │                 1 │
└───────────┴───────────┴───────────────┴───────────────────┘
```

Comme cette table n'a pas de fragmentation et comme nous modifions
la première ligne, cette nouvelle ligne va se retrouver en fin de fichier.
Elle change donc de bloc. Le CTID l'indique bien (passage du bloc 0 au bloc 4).
La nouvelle colonne de statistique `n_tup_newpage_upd` est bien mise à jour.

Modifions de nouveau la même ligne :

```
-- test #2
select ctid from t1 where id=1;

┌────────┐
│  ctid  │
├────────┤
│ (4,97) │
└────────┘

update t1 set id=id where id=1;
select ctid from t1 where id=1;

┌────────┐
│  ctid  │
├────────┤
│ (4,98) │
└────────┘

select n_tup_ins, n_tup_upd, n_tup_hot_upd, n_tup_newpage_upd
  from pg_stat_user_tables
  where relname='t1';

┌───────────┬───────────┬───────────────┬───────────────────┐
│ n_tup_ins │ n_tup_upd │ n_tup_hot_upd │ n_tup_newpage_upd │
├───────────┼───────────┼───────────────┼───────────────────┤
│      1000 │         2 │             1 │                 1 │
└───────────┴───────────┴───────────────┴───────────────────┘
```

La nouvelle version de la ligne est ajoutée toujours en fin de fichier (pas de
VACUUM entre les deux) mais il se trouve qu'il s'agit cette fois du même bloc.
C'est donc l'ancien champ des statistiques qui est incrémenté. Nous voyons donc
bien les deux informations séparément.

</div>
