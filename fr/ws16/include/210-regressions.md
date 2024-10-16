<!--
Les sources pour ce sujet sont :

* https://git.postgresql.org/gitweb/?p=postgresql.git;a=commit;h=b0f6c437160db640d4ea3e49398ebc3ba39d1982

-->

<div class="slide-content">

  * Paramètres supprimés
    + `vacuum_defer_cleanup_age`
    + `promote_trigger_file`
  * Paramètre renommé
    + `force_parallel_mode` devient `debug_parallel_query`

</div>

<div class="notes">

PostgreSQL 16 supprime deux paramètres qui sont devenus inutiles. Dus
aux récents changements sur la commande `VACUUM`, le paramètre
`vacuum_defer_cleanup_age` est devenu inutile.

Le paramètre `promote_trigger_file` permettait d'indiquer le nom d'un fichier
dont la présence demandait à une instance PostgreSQL secondaire de quitter le 
mode lecture seule et l'application de la réplication. Il existe deux autres 
moyens de le faire (un via le shell, un autre via une commande SQL), un paramètre 
comme celui-ci n'était donc pas vraiment utile.

Quant au paramètre renommé, il a été considéré qu'il fallait mettre l'accent sur
le fait qu'il s'agit d'un paramètre de débogage, pas d'un paramètre
d'utilisation normale. L'ajout du mot `debug` dans le nom du paramètre aide à
cela.

</div>
