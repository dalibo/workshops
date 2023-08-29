<!--
Les sources pour ce sujet sont :

* https://www.postgresql.org/message-id/flat/2923349.1634942313@sss.pgh.pa.us
* https://git.postgresql.org/pg/commitdiff/cf0cab868aa4758b7eec5f9412f2ec74acda7f45

-->

<div class="slide-content">

* Changement sur la compatibilité des outils en version 15 :
  + `psql`, `pg_dump` et `pg_dumpall` ne supportent plus l'accès à des serveurs 9.1 ou antérieur
  + `pg_upgrade` ne supporte plus la mise à niveau depuis une instance 9.1 ou antérieur.

</div>

<div class="notes">

Cette version contient des modifications de catalogue qui impactent la 
compatibilité avec d'anciennes versions. Le client `psql` ne supporte
ainsi plus d'accéder à des serveurs de versions 9.1 ou antérieures.

Les outils `pg_dump` et `pg_dumpall` ne supportent plus d'effectuer des exports de
données depuis une instance de version 9.1 ou antérieure. La restauration 
d'anciennes archives n'est par ailleurs pas garantie.

De plus, `pg_ugrade` ne supporte plus la mise à niveau depuis une instance de 
version 9.1 ou antérieure.

Ces régressions peuvent être particulièrement impactantes pour les migrations. 
Une version intermédiaire devra dans certains cas être utilisée pour la mise à 
niveau en 15 d'une très ancienne version.

</div>
