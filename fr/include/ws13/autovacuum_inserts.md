<!--
Les commits sur ce sujet sont :

| Sujet                    | Lien                                                                                                        |
|==========================|=============================================================================================================|
| insert, autovacuum       | https://git.postgresql.org/pg/commitdiff/b07642dbcd8d5de05f0ee1dbb72dd6760dd30436                           |

-->

<!-- #### INSERT et autovacuum -->

<div class="slide-content">

  * Avant PostgreSQL v13 :
    * des INSERTs déclenchent un ANALYZE automatique
    * mais pas de VACUUM
  * VACUUM important pour les VM et FSM
  * Deux nouveaux paramètres :
    * autovacuum_vacuum_insert_threshold
    * autovacuum_vacuum_insert_scale_factor

</div>

<div class="notes">

Avant la version 13, les `INSERT` n'étaient considérés par l'autovacuum que pour
les opérations `ANALYZE`. Cependant, le `VACUUM` a aussi une importance pour
la mise à jour des fichiers de méta-données que sont la FSM (_Free Space Map_)
et la VM (_Visibility Map_). Notamment, pour cette dernière, cela permet à
PostgreSQL de savoir si un bloc ne contient que des lignes vivantes, ce qui
permet à l'exécuteur de passer par un `Index Only Scan` au lieu d'un `Index
Scan` probablement plus lent.

Ainsi, exécuter un `VACUUM` régulièrement en fonction du nombre
d'insertions réalisé est important. L'ancien comportement pouvait poser problème
pour les tables uniquement en insertion.

Les développeurs de PostgreSQL ont donc ajouté cette fonctionnalité en
intégrant deux nouveaux paramètres, dont le franchissement va déclencher un `VACUUM` :

  * `autovacuum_vacuum_insert_threshold` indique le nombre minimum de lignes
    devant être insérées, par défaut à 1000 ;
  * `autovacuum_vacuum_insert_scale_factor` indique le ratio minimum de
    lignes, par défaut à 0.2.

Il est à noter que nous retrouvons l'ancien comportement (pré-v13) en
configurant ces deux paramètres à la valeur -1.

Le `VACUUM` exécuté fonctionne exactement de la même façon que tout autre
`VACUUM`. Il va notamment nettoyer les index même si, strictement
parlant, ce n'est pas indispensable dans ce cas.

</div>

