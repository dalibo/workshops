<!--
Les sources pour ce sujet sont :

* https://git.postgresql.org/gitweb/?p=postgresql.git;a=commit;h=989596152
* https://git.postgresql.org/gitweb/?p=postgresql.git;a=commit;h=be85727a3
* https://git.postgresql.org/gitweb/?p=postgresql.git;a=commit;h=d5e8930f5

et
* https://git.postgresql.org/gitweb/?p=postgresql.git;a=commit;h=65aaed22a

-->

<div class="slide-content">

  * Amélioration des performances d'export de bases avec de nombreux objets
    + désormais une seule requête pour toutes les tables à exporter
    + élimination de sous-requêtes non nécessaires
    + utilisation de `PREPARE`/`EXECUTE` pour les requêtes répétitives
  * Amélioration des performances d'export parallélisé de tables TOAST
    + données TOAST désormais comptabilisées dans la planification d'un export
    parallélisé

</div>


<div class="notes">

Diverses optimisations ont été apportées pour améliorer les performances de 
l'outil `pg_dump` lorsque l'on souhaite exporter un grand nombre d'objets. 
Avant la version 15, `pg_dump` lançait une requête pour chaque objet dont il 
devait exporter les données. Désormais, il ne lance plus qu'une seule requête 
et c'est une clause `WHERE` qui permet de se limiter aux seuls objets voulus 
dans l'export.

Lorsque l'on exporte beaucoup d'objets similaires, il est probable qu'une même 
requête soit répétée de nombreuses fois, en changeant seulement la valeur des 
paramètres. C'est pourquoi `pg_dump` utilise désormais les clauses `PREPARE` et 
`EXECUTE`, afin de ne calculer qu'une seule fois le plan d'execution.

Afin d'éviter l'utilisation d'une sous-requête, qui peut pénaliser les 
performances lorsqu'un grand nombre d'objets sont exportés, `pg_dump` récupère 
désormais les noms de rôles via leurs OIDs. Une autre sous-requête vérifiant
le lien de dépendance (`pg_depend`) entre relations et séquences a été supprimée 
car cette vérification était redondante avec une autre déjà en place.

L'export parallélisé des tables TOAST bénéficie d'une amélioration de ses 
performances car l'estimation du volume des tables a été corrigée. Cette 
estimation ne prenait pas en compte les champs stockés dans les tables TOAST 
dans le calcul du volume des tables à exporter, ceci pouvait déséquilibrer la 
répartition de charge des processus lancés en parallèle.


<!-- Note
* une seule requête pour toutes les tables à exporter
  + utilisation de la fonction unnest() => d'où la fin de support < 9.2
* Utilisation de PREPARE/EXECUTE pour les requêtes répétitives de pg_dump.
* élimination des la sous requête SELECT pour username_subquery


Évitez les requêtes par objet dans les chemins critiques en termes de performances dans pg_dump.

Au lieu de lancer une requête secondaire de collecte de données contre
chaque table à exporter, lancer une seule requête, avec une clause WHERE
limitant son application aux seules tables à exporter.
De même pour les index, les contraintes et les déclencheurs.

Avant, on allait chercher les données table par table sur les fichiers.
Désormais `pg_dump` ne lance qu'une requête, en filtrant les tables souhaitées 
dans une clause WHERE

Also drop an entirely unnecessary sub-SELECT to check on the
pg_depend status of a sequence relation: we already have a
LEFT JOIN to fetch the row of interest in the FROM clause.
!-->
</div>
