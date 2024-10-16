<!--
Les commits sur ce sujet sont :

* https://www.postgresql.org/message-id/E1ncnD6-000t0C-Vy@gemulon.postgresql.org
* https://www.postgresql.org/message-id/E1ncfzV-000pzr-DF@gemulon.postgresql.org

-->

<div class="slide-content">

* Nouvelles statistiques ajoutées dans `pg_stat_statements` pour tracer :

  + l'activité de JIT
  + les temps d'accès aux fichiers temporaires
* L'extension passe en 1.10

</div>

<div class="notes">

La vue [pg_stat_statement], fournie avec l'extension éponyme, s'est vue
ajouter une série de compteurs permettant de suivre l'activité du compilateur à la volée (JIT) sur un
serveur. Ces informations sont très intéressantes car jusqu'à maintenant, il n'y
avait aucun moyen de superviser l'utilisation de JIT. Bien souvent, les seules
fois où l'on entendait parler du JIT étaient quand les temps de planifications 
pénalisaient le temps d'exécution de la requête.

Voici la liste des compteurs qui sont cumulés, comme les autres informations de
cette vue :

* `jit_functions` : nombre total de fonctions compilées par JIT pour cette
  requête ;
* `jit_generation_time` : temps total consacré à générer du code JIT pour cette
  requête, il est exprimé en millisecondes ;
* `jit_inlining_count` : nombre de fois où les fonctions ont été incluses ;
* `jit_inlining_time` : temps total consacré à l'inclusion des fonctions
  pour cette requête, il est exprimé en millisecondes ;
* `jit_optimization_count` : nombre de requêtes qui ont été optimisées ;
* `jit_optimization_time` : temps total consacré à l'optimisation pour cette
  requête, il est exprimé en millisecondes ;
* `jit_emission_count` : nombre de fois où du code a été émis ;
* `jit_emission_time` : temps total consacré à émettre du code, il est exprimé
  en millisecondes.



Des informations concernant les temps d'accès aux fichiers temporaires ont
également été ajoutées :

* `temp_blk_read_time` : temps total consacré à la lecture de blocs de fichiers
  temporaires, il est exprimé en millisecondes. Ce paramètre est valorisé à zéro
  si `track_io_timing` est désactivé.

* `temp_blk_write_time` : temps total consacré à écrire des blocs de fichiers
  temporaires, il est exprimé en millisecondes. Ce paramètre est valorisé à zéro
  si `track_io_timing` est désactivé.


Suite à l'ajout de ces fonctionnalités, l'extension passe en version 1.10.

[pg_stat_statements]: https://www.postgresql.org/docs/15/pgstatstatements.html

</div>
