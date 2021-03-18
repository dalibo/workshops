<!--

git :
https://git.postgresql.org/gitweb/?p=postgresql.git;a=commitdiff;h=1e6148032e4d27aec75c49264b47ad193405a919

discussion :
https://www.postgresql.org/message-id/flat/19513901543181143%40sas1-19a94364928d.qloud-c.yandex.net

-->

<div class="slide-content">

  * Plus besoin de redémarrer un secondaire pour modifier les paramètres de réplication
  * Notamment les paramètres `primary_conninfo` et `primary_slot_name`
  * Évite la déconnexion des utilisateurs

</div>

<div class="notes">

Quand le paramétrage de la réplication d'un serveur secondaire était modifié
(paramètres `primary_conninfo` et `primary_slot_name` notamment),
il était auparavant nécessaire de redémarrer l'instance pour tenir compte de
ces modifications, ce qui coupait les connexions en cours.

À présent, il suffit d'une simple relecture de configuration sur le secondaire
après modification des paramètres. La modification peut se faire en éditant le
fichier `postgresql.conf`, n'importe quel fichier inclu, ou encore à l'aide de
la requête `ALTER SYSTEM SET <nom> TO <valeur>`. Le rechargement quant à lui
peut être effectué à l'aide de la requête `SELECT pg_reload_conf()` ou encore
avec la commande `pg_ctl -D "$PGDATA" reload`, etc.

Notez que le mot de passe associé à l'utilisateur spécifié dans le paramètre 
`primary_conninfo` est souvent spécifié dans un fichier `.pgpass`, qui doit 
être édité séparément et dont la prise en compte ne nécessite pas de 
rechargement de la configuration.

En revanche, cette amélioration simplifiera la suppression d'un slot,
un changement d'utilisateur de réplication ou le renforcement de la
configuration SSL.

Elle simplifiera surtout, dans une configuration à trois serveurs ou plus, le
raccrochage d'un secondaire à un nouveau primaire suite à une bascule,
ou le passage à une réplication en cascade.

</div>
