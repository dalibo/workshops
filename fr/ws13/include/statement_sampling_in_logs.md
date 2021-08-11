
<!--
Les commits sur ce sujet sont :

https://git.postgresql.org/gitweb/?p=postgresql.git;a=commitdiff;h=6e3e6cc0e884a6091e1094dff29db430af08fb93

Discussion :

https://postgr.es/m/bbe0a1a8-a8f7-3be2-155a-888e661cc06c@anayrat.info

-->

<div class="slide-content">

* `log_min_duration_sample` : durée minimum requise pour qu'une requête
  échantillonnée puisse être tracée.
* `log_statement_sample_rate` : probabilité qu'une requête durant plus de
  `log_min_duration_sample` soit tracée.
* priorité de `log_min_duration_statement` sur `log_min_duration_sample`.

</div>

<div class="notes"> 

Activer la trace des requêtes avec un seuil trop bas via le paramètre
`log_min_duration_statement` peut avoir un impact important sur les
performances ou sur le remplissage des disques à cause de la quantité
d'écritures réalisées.

Un nouveau mécanisme a dont été introduit pour faire de l'échantillonnage. Ce
mécanisme s'appuie sur deux paramètres pour configurer un seuil de
déclenchement de l'échantillonnage dans les traces : `log_min_duration_sample`,
et un taux de requête échantillonné : `log_statement_sample_rate`.

Par défaut, l'échantillonnage est désactivé (`log_min_duration_sample = -1`).
Le taux d'échantillonnage, dont la valeur est comprise entre `0.0` et `1.0`, a
pour valeur par défaut `1.0`. La modification de ces paramètres peut être faite
jusqu'au niveau de la transaction, il faut cependant se connecter avec un
utilisateur bénéficiant de l'attribut `SUPERUSER` pour cela.

Si le paramètre `log_min_duration_statement` est configuré, il a la priorité.
Dans ce cas, seules les requêtes dont la durée est supérieure à
`log_min_duration_sample` et inférieure à `log_min_duration_statement` sont
échantillonnées. Toutes les requêtes dont la durée est supérieure à
`log_min_duration_statement` sont tracées normalement.

</div>

