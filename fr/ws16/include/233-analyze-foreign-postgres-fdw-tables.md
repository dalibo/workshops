<!--
Les sources pour ce sujet sont :

* https://git.postgresql.org/gitweb/?p=postgresql.git;a=commit;h=8ad51b5f446b5c19ba2c0033a0f7b3180b3b6d95

Discussion :

* Discussion: 

-->

<div class="slide-content">

  * postgres_fdw
  * `ANALYZE` plus efficace sur des tables distantes
  * Option `analyze_sampling`
    + SERVER
    + FOREIGN TABLE

</div>

<div class="notes">

Le calcul de statistiques sur des tables distantes avec l'extension
`postgres_fdw` est nettement amélioré. Jusqu'à présent, lorsque `ANALYZE` était
exécuté sur une table distante, l'échantillonnage était effectué localement à
l'instance. Les données étaient donc intégralement rapatriées avant que ne soient effectuées
les opérations d'échantillonnage. Pour des grosses tables, cette manière de faire
était tout sauf optimisée.

Il est désormais possible d'effectuer l'échantillonnage sur le serveur distant
grâce à l'option `analyze_sampling`. La volumétrie transférée est alors bien plus basse.
Le calcul des statistiques des données sur cet échantillon se fait toujours sur 
l'instance qui lance `ANALYZE`. Cette option peut prendre les valeurs
`off`, `auto`, `system`, `bernoulli` et `random`. La valeur par défaut est
`auto` qui permettra d'utiliser soit `bernoulli` soit `random`. Elle peut être
appliquée soit sur l'objet `SERVER` soit sur la `FOREIGN TABLE`. 

Prenons l'exemple d'une table de 20 millions de lignes avec une seule colonne uuid.
Les différences entre les temps d'exécution sont notables.
Lorsque les données sont récupérées, il faut presque 7 secondes pour y
arriver, moins de 1 secondes dans tous les autres cas. Le test a été fait avec
deux instances sur un même poste. Dans le cas d'instances séparées sur des
datacenters ou VLAN différents, les temps de latence pourraient être encore plus
impactant. 

```sql
-- Sur le serveur distant :
CREATE TABLE t1_fdw AS SELECT gen_random_uuid() AS id FROM generate_series(1,20000000);
```

```sql
-- Sur l'instance locale :
postgres=# CREATE EXTENSION postgres_fdw;
postgres=# CREATE SERVER serveur2
  FOREIGN DATA WRAPPER postgres_fdw
  OPTIONS (host '10.0.3.114',
           port '5432',
           dbname 'postgres') ;
postgres=# CREATE USER MAPPING FOR postgres SERVER serveur2 OPTIONS (user 'postgres');
CREATE USER MAPPING

postgres=# CREATE FOREIGN TABLE t1_fdw (id uuid) SERVER serveur2 OPTIONS ( analyze_sampling 'off');
CREATE FOREIGN TABLE

-- off
postgres=# ANALYZE VERBOSE t1_fdw;
INFO:  analyzing "public.t1_fdw"
INFO:  "t1_fdw": table contains 20000000 rows, 30000 rows in sample
ANALYZE
Time: 6922,019 ms (00:06,922)

-- random
postgres=# ALTER FOREIGN TABLE t1_fdw OPTIONS ( SET analyze_sampling 'random');
ALTER FOREIGN TABLE
postgres=# ANALYZE VERBOSE t1_fdw;
INFO:  analyzing "public.t1_fdw"
INFO:  "t1_fdw": table contains 19998332 rows, 29969 rows in sample
ANALYZE
Time: 629,190 ms

-- system
postgres=# ALTER FOREIGN TABLE t1_fdw OPTIONS ( SET analyze_sampling 'system');
ALTER FOREIGN TABLE
postgres=# ANALYZE VERBOSE t1_fdw;
INFO:  analyzing "public.t1_fdw"
INFO:  "t1_fdw": table contains 19998332 rows, 30000 rows in sample
ANALYZE
Time: 82,832 ms

-- bernoulli
postgres=# ALTER FOREIGN TABLE t1_fdw OPTIONS ( SET analyze_sampling 'bernoulli');
ALTER FOREIGN TABLE
postgres=# ANALYZE VERBOSE t1_fdw;
INFO:  analyzing "public.t1_fdw"
INFO:  "t1_fdw": table contains 19998332 rows, 29875 rows in sample
ANALYZE
Time: 303,548 ms


```

</div>
