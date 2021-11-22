<!--
Les commits sur ce sujet sont :

* https://commitfest.postgresql.org/31/2639/
* https://git.postgresql.org/gitweb/?p=postgresql.git;a=commit;h=960869da0803427d14335bba24393f414b476e2c

Discussion

* https://gitlab.dalibo.info/formation/workshops/-/issues/131

-->

<div class="slide-content">

* Ajout des colonnes suivantes à la vue système `pg_stat_database` :
    * `session_time`
    * `active_time`
    * `idle_in_transaction_time`
    * `sessions`
    * `sessions_abandoned`
    * `sessions_fatal`
    * `sessions_killed`

</div>

<div class="notes">

La vue `pg_stat_database` dipose à présent de nouveaux compteurs orientés sessions et temps de session :

* `session_time` : temps passé par les sessions sur cette base de données. Ce compteur n'est mis à jour que lorsque l'état d'une session change.
* `active_time` : temps passé à exécuter des requêtes SQL sur cette base de données. Correspond aux états `active` et `fastpath function call` dans `pg_stat_activity`.
* `idle_in_transaction_time` : temps passé à l'état `idle` dans une transaction sur cette base de données. Correspond aux états `idle in transaction` et `idle in transaction (aborted)` dans `pg_stat_activity`.
* `sessions` : nombre total de sessions ayant établies une connexion à cette base de données.
* `sessions_abandoned` : nombre de sessions interrompues à cause d'une perte de connexion avec le client.
* `sessions_fatal` : nombre de sessions interrompues par des erreurs fatales.
* `sessions_killed` : nombre de sessions interrompues par des demandes administrateur.

Ces nouvelles statistiques d'activité permettront d'avoir un aperçu de
l'activité des sessions sur une base de données. C'est un réel plus lors de la
réalisation d'un audit car elles permettront de repérer facilement des 
problèmes de connexion (`sessions_abandoned`), d'éventuels passages de l'_OOM
killer_ (`sessions_fatal`) ou des problèmes de stabilité (`sessions_fatal`).
Cela permettra également d'évaluer plus facilement la pertinence de la mise en
place d'un pooler de connexion (`*_time`).
 
La présence de ces métriques dans l'instance simplifiera également leur
obtention pour les outils de supervision et métrologie. En effet, certaines
n'étaient accessibles que par analyse des traces (`session time`, `sessions`)
ou tout simplement impossible à obtenir.
</div>