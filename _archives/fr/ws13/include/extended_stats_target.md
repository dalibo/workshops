<!--
Les commits sur ce sujet sont :

https://git.postgresql.org/gitweb/?p=postgresql.git;a=commitdiff;h=d06215d03b50c264a0f31e335b895ee1b6753e68

Discussion :

https://postgr.es/m/20190618213357.vli3i23vpkset2xd@development

-->

<div class="slide-content">

* Permet de spécifier séparément la finesse de calcul pour les statistiques
  classiques et étendues
* Nouvelle commande :

  `ALTER STATISTICS stat_name SET STATISTICS target_value`
</div>
<div class="notes">

PostgreSQL dispose de deux types de statistiques sur les données :

* statistiques sur les colonnes **individuellement** (fraction de valeurs nulles,
  valeurs distinctes, valeurs les plus fréquentes, histogrammes etc..) ;
* statistiques sur **plusieurs colonnes** (dépendance entre colonnes, valeurs les
  plus fréquentes et nombre de valeurs distinctes).

Lors du calcul des statistiques, il est possible de modifier le nombre de lignes
échantillonnées et la finesse des statistiques calculées. Cette finesse est
définie globalement par le paramètre `default_statistics_target` ou
spécifiquement à chaque colonne à l'aide de l'ordre SQL
`ALTER TABLE ... ALTER COLUMN ... SET STATISTICS ...`.

Jusqu'à présent, ce paramétrage était valable à la fois pour les statistiques
de colonnes et pour les statistiques étendues.

Il est désormais possible de les découpler et de spécifier un paramétrage
spécifique aux statistiques étendues grâce à la commande suivante :

```
ALTER STATISTICS stat_name SET STATISTICS target_value;
```

Il est possible de conserver le comportement historique avec `target_value`
égal à `-1`. Une valeur de `0` permet de désactiver complètement la collecte
pour les statistiques étendues seulement. Enfin, une valeur supérieure à zéro
définit une valeur spécifique pour la finesse des statistiques étendues.

</div>
