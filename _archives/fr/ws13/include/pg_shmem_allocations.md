<!---

https://git.postgresql.org/gitweb/?p=postgresql.git;a=commitdiff;h=ed10f32e37e9a16814c25e400d7826745ae3c797

Discussion :  https://www.postgresql.org/message-id/flat/20140504114417.GM12715%40awork2.anarazel.de

This tells you about allocations that have been made from the main
shared memory segment. The original patch also tried to show information
about dynamic shared memory allocation as well, but I decided to
leave that problem for another time.

<entry>The name of the shared memory allocation. NULL for unused memory
+      and <literal>&lt;anonymous&gt;</literal> for anonymous
+      allocations.</entry>
+     </row>
+
+     <row>
+      <entry><structfield>off</structfield></entry>
+      <entry><type>bigint</type></entry>
+      <entry>The offset at which the allocation starts. NULL for anonymous
+      allocations and unused memory.</entry>
+     </row>
+
+     <row>
+      <entry><structfield>size</structfield></entry>
+      <entry><type>bigint</type></entry>
+      <entry>Size of the allocation</entry>
+     </row>
+
+     <row>
+      <entry><structfield>allocated_size</structfield></entry>
+      <entry><type>bigint</type></entry>
+      <entry>Size of the allocation including padding. For anonymous
+      allocations, no information about padding is available, so the
+      <literal>size</literal> and <literal>allocated_size</literal> columns
+      will always be equal. Padding is not meaningful for free memory, so
+      the columns will be equal in that case also.</entry>


Pour information, le padding en question correspond à la taille de
PG_CACHE_LINE_SIZE, soit 128 par défaut. Voir src/include/pg_config_manual.h.
--->

<div class="slide-content">

Vue pg_shmem_allocations :

  * Voir les allocations du segment principal de mémoire partagée
  * PostgreSQL et extensions

</div>

<div class="notes">

Cette vue liste l'attribution des blocs de la mémoire partagée statique de
l'instance. Les segments de mémoire partagée dynamique n'y sont pas
répertoriés.

Les principales lignes qui y figurent sont :

```
postgres=# SELECT * FROM pg_shmem_allocations ORDER BY size DESC LIMIT 5;

        name        |    off    |   size    | allocated_size
--------------------+-----------+-----------+----------------
 Buffer Blocks      |   6442752 | 134217728 |      134217728
 <anonymous>        |         ¤ |   4726784 |        4726784
 XLOG Ctl           |     53888 |   4208272 |        4208384
 ¤                  | 147197696 |   1913088 |        1913088
 Buffer Descriptors |   5394176 |   1048576 |        1048576
```

La colonne `off` (ie. _offset_), indique l'emplacement. Les deux champs de
taille ne diffèrent que par l'alignement de 128 octets imposé en mémoire
partagée.

L'exemple ci-dessus provient d'une installation PostgreSQL 13 par défaut.
La taille la plus importante correspond aux 128 Mo de _shared buffers_.

La mémoire qui n'est pas encore utilisée apparaît également dans le résultat de la
requête. Elle correspond à la colonne dont le nom est valorisée à `NULL` (ici
représenté par `¤`).

L'un des intérêts est de suivre la consommation d'objets de la mémoire partagée,
notamment certaines extensions.

Ci-après un exemple illustré avec l'extension `pg_stat_statements`. Voici
l'état original de la mémoire partagée:

~~~console
postgres=# SELECT pg_size_pretty(sum(allocated_size))
           FROM pg_shmem_allocations ;

 total
--------
 142 MB
(1 row)
~~~

Nous activons l'extension `pg_stat_statements` et paramétrons le nombre maximum
de requête qu'il peut suivre à 100.000:

~~~console
$ cat <<EOF >> $PGDATA/postgresql.conf
shared_preload_libraries = 'pg_stat_statements'
pg_stat_statements.max = 100000
EOF

$ pg_ctl restart
~~~

Après le redémarrage de l'instance requis par `pg_stat_statements`, nous
observons une augmentation de la taille totale de la mémoire partagée
principale :

~~~console
postgres=# SELECT pg_size_pretty(sum(allocated_size)) FROM pg_shmem_allocations;

 pg_size_pretty
----------------
 171 MB
~~~

Pour 100,000 requêtes uniques suivies, `pg_stat_statements` consomme donc
environ 29 MB de mémoire partagée.

Inspecter les détails de cette mémoire partagée principale et, pour les plus
curieux, un détour dans le code nous permet de mieux identifier la
consommation:

~~~console
postgres=# SELECT name, pg_size_pretty(allocated_size)
           FROM pg_shmem_allocations
           WHERE name ~'anon|statements'
           ORDER BY allocated_size;

          name           | pg_size_pretty
-------------------------+----------------
 pg_stat_statements      | 128 bytes
 pg_stat_statements hash | 4992 bytes
 <anonymous>             | 33 MB
~~~

Deux nouveaux objets apparaissent en mémoire partagée principale et nous
constatons l'augmentation de l'espace anonyme.

Le premier objet détient des informations globales à l'extension, le second
détient la table de hashage et les statistiques référencées par celle-ci pour
chaque requête sont allouées dans l'espace anonyme. Notez que ce dernier ne
concerne que les statistiques, le texte des requêtes est quant à lui écrit sur
disque, permettant ainsi une taille illimitée au besoin.

<!--
FIXME : Exemple utile ?


En jouant sur max_locks_per_transactions (64->1000, max_connections à 100) on peut voir des changements mais on n'arrive pas à des valeurs énormes 

  <anonymous>                         | 228592256

  <anonymous>                         |  24926848

  LOCK hash                           |     66392

  LOCK hash                           |      4952

  PROCLOCK hash                       |    131928

  PROCLOCK hash                       |      9048

-->


</div>
