<!--
Les commits sur ce sujet sont :

* https://git.postgresql.org/gitweb/?p=postgresql.git;a=commit;h=43c1c4f65eab77bcfc4f535a7e9ac0421e0cf2a5
* https://git.postgresql.org/gitweb/?p=postgresql.git;a=commit;h=bd1788051b02cfddcd9ef0e2fd094972f372b8fd

Discussion

* https://gitlab.dalibo.info/formation/workshops/-/issues/160

-->

<div class="slide-content">

* Ajout de deux nouvelles variables serveurs :
  + `shared_memory_size` : détermine la taille de la mémoire partagée
  + `shared_memory_size_in_huge_pages` : détermine le nombre de _Huge Pages_ 
    nécessaires pour stocker la mémoire partagée
* Englobe les éléments chargés avec `shared_preload_libraries`
* Uniquement accessible en lecture seule

</div>

<div class="notes">

La variable `shared_memory_size` renvoie la taille de la mémoire partagée de PostgreSQL.
Le résultat tient bien entendu compte des éventuels modules et extensions qui pourraient 
consommer de la mémoire partagée supplémentaire. Il est donc calculé après le chargement 
des modules complémentaires (`shared_preload_libraries`).

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
apparu en version 14 est définit. Si c'est le cas, il sera utiliser pour le calcul sinon, c'est le 
paramétrage du système qui sera utilisé (`/proc/meminfo`).

Il faut également que PostgreSQL puisse utiliser les _Huge Pages_. Le paramètre `huge_pages` doit  
donc être définit à `on` ou `try`. Si ce n'est pas le cas, `shared_memory_size_in_huge_pages` 
retournera `-1`.

Autre particularité avec ces deux variables, ce sont des variables dites _calculées durant l'exécution_ 
(`runtime-computed GUC`). Elles nécessitent de charger différents éléments en mémoire avant de 
retourner une valeur viable. Avec la version 15 de PostgreSQL, il est maintenant possible d'estimer leur 
valeur sans avoir à allouer de mémoire partagée avec la commande suivante :

```bash
postgres -C shared_memory_size -D $PGDATA
postgres -C shared_memory_size_in_huge_pages -D $PGDATA
```

On peut donc dorénavant savoir avant de démarrer une instance PostgreSQL (cette commande ne fonctionne pas 
sur une instance démarrée), combien celle-ci va utiliser de mémoire partagée et de combien de 
_Huge Pages_ mon système à besoin.

</div>
