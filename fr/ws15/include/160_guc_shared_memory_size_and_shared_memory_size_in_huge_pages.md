<!--
Les commits sur ce sujet sont :

* https://git.postgresql.org/gitweb/?p=postgresql.git;a=commit;h=43c1c4f65eab77bcfc4f535a7e9ac0421e0cf2a5
* https://git.postgresql.org/gitweb/?p=postgresql.git;a=commit;h=bd1788051b02cfddcd9ef0e2fd094972f372b8fd

Discussion

* https://gitlab.dalibo.info/formation/workshops/-/issues/160

-->

<div class="slide-content">

* Ajout de deux nouvelles variables serveur :
  + `shared_memory_size` : détermine la taille de la mémoire partagée
  + `shared_memory_size_in_huge_pages` : détermine le nombre de _Huge Pages_ 
    nécessaires pour stocker la mémoire partagée
* Englobe les éléments chargés avec `shared_preload_libraries`
* Uniquement accessible en lecture seule

</div>

<div class="notes">

La variable `shared_memory_size` renvoie la taille de la mémoire partagée de PostgreSQL.
Le résultat est calculé après le chargement des modules complémentaires (`shared_preload_libraries`).
Il tient donc compte des éventuels modules et extensions qui pourraient 
consommer de la mémoire partagée supplémentaire.

```sql
# show shared_memory_size;
 shared_memory_size 
--------------------
 143MB
```

On obtient quelque chose de similaire en faisant la somme des zones de mémoire partagée allouées 
avec la vue `pg_shmem_allocations` :

```sql
# select pg_size_pretty(sum(allocated_size)) from pg_shmem_allocations;
 pg_size_pretty 
----------------
 143 MB
```

La variable `shared_memory_size_in_huge_pages` va quant à elle indiquer le nombre de _Huge Pages_ 
nécessaires pour stocker la mémoire partagée de PostgreSQL. Elle est basée sur la valeur de  
`shared_memory_size` vue précédemment et sur la taille des _Huge Pages_ du système. Pour 
récupérer cette taille, PostgreSQL va en premier lieu regarder si le paramètre `huge_page_size` 
apparu en version 14 est défini. Si c'est le cas, il sera utilisé pour le calcul sinon, c'est le 
paramétrage du système qui sera utilisé (`/proc/meminfo`).

```sql
# show shared_memory_size_in_huge_pages;
 shared_memory_size_in_huge_pages
----------------------------------
 72
```

Il faut également que PostgreSQL puisse utiliser les _Huge Pages_. Le paramètre `huge_pages` doit  
donc être défini à `on` ou `try`. Si elles ne sont pas utilisables ou si l'on se trouve sur un 
autre système que linux, `shared_memory_size_in_huge_pages` retournera `-1`.

Autre particularité avec ces deux variables, ce sont des variables _calculées durant l'exécution_ 
(`runtime-computed GUC`). Dans les versions antérieures, la consultation de ce type de paramètre 
avec la commande `postgres -C` renvoyait des valeurs erronées car elle nécessitait le chargement 
d'éléments complémentaires (ce que ne faisait pas l'ancienne implémentation). La version 15 vient corriger 
ce problème et permet d'obtenir des valeurs correctes pour ces paramètres. Seule restriction, les 
paramètres `runtime-computed GUC` ne sont consultables avec `postgres -C` que lorsque 
l'instance est arrêtée.

```bash
postgres -C shared_memory_size -D $PGDATA
postgres -C shared_memory_size_in_huge_pages -D $PGDATA
```

On peut donc dorénavant savoir combien de mémoire partagée et de _Huge Pages_
le système à besoin avant de démarrer une instance PostgreSQL.

</div> 
