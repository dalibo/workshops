<!--
Les commits sur ce sujet sont :

* https://commitfest.postgresql.org/31/2802/
* https://git.postgresql.org/gitweb/?p=postgresql.git;a=commit;h=942305a36365433eff3c1937945758f2dbf1662b

Discussion

* https://gitlab.dalibo.info/formation/workshops/-/issues/102

-->

<div class="slide-content">

* Le paramètre `restore_command` ne nécessite plus de redémarrage
* Applicable pour les instances secondaires

</div>

<div class="notes">

La modification du paramètres `restore_command` ne nécessite plus de
redémarrage pour que l'instance secondaire prenne en compte sa nouvelle
valeur. Un simple rechargement suffit.

Cette amélioration permet de ne plus redémarrer un réplica lorsque la provenance
des archives de journaux de transaction est modifiée. Les sessions en cours sont
donc maintenues sans risque lors de la manipulation.

</div>
