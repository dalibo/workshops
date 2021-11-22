<!--
Les commits sur ce sujet sont :

* https://git.postgresql.org/gitweb/?p=postgresql.git;a=commit;h=e19594c5c059d2e071b67d87ae84f569a52d2e32
* https://git.postgresql.org/gitweb/?p=postgresql.git;a=commit;h=bbcc4eb2e08fb6e4535c7f84b2c00f3ad508bb9b

Discussion

* https://gitlab.dalibo.info/formation/workshops/-/issues/141

-->

<div class="slide-content">

  * VACUUM
    +  `vacuum_cost_page_miss` = 2 (autrefois : 10)
  * Checkpoint :
    + `checkpoint_completion_target` = 0.9 par défaut
  * Nouveaux paramètres :
    + `huge_page_size`
    + `log_recovery_conflict_waits`

</div>

<div class="notes">

La version 14 apporte quelques modifications mineures de configuration :

**vacuum_cost_page_miss** :

Sa valeur par défaut passe de 10 à 2. Cette modification
  diminue la pénalité associée à la lecture de page qui ne sont pas dans le cache de
  l'instance par le _vacuum_. Cela va donc permettre à l'autovacuum (voire le vacuum si
  `vacuum_cost_delay` est supérieur à zéro) de traiter plus de pages avant de se mettre
  en pause. Ce changement reflète l'amélioration des performances des serveurs due à
  l'évolution du stockage et à la quantité de RAM disponible.

**checkpoint_completion_target** :

La valeur par défaut passe de 0.5 à 0.9. Ce paramétrage
  était déjà largement adopté par la communauté et permet de lisser les écritures faites lors
  d'un `CHECKPOINT` sur une durée plus longue (90 % de `checkpoint_timeout`, qui vaut 5 minutes).
  Cela a pour effet
  de limiter les pics d'IO suite aux _checkpoints_.

**huge_page_size** :

Ce paramètre permet de surcharger la configuration système pour la taille des _Huge Pages_. Par défaut, PostgreSQL utilisera la valeur du système d'exploitation.

**log_recovery_conflict_waits** :

Ce paramètre, une fois activé, permet de tracer toute attente due à un conflit de réplication. Il n'est donc intéressant et pris en compte que sur un serveur secondaire.

</div>
