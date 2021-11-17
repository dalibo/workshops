<!-- 

https://www.postgresql.org/docs/13/runtime-config-resource.html#GUC-MAINTENANCE-IO-CONCURRENCY

https://git.postgresql.org/gitweb/?p=postgresql.git;a=commitdiff;h=fc34b0d9de27ab5ac2887da00b3892bdabd89e45

https://www.postgresql.org/message-id/flat/CA%2BhUKGJUw08dPs_3EUcdO6M90GnjofPYrWp4YSLaBkgYwS-AqA%40mail.gmail.com

-->

<div class="slide-content">

  * Nouveau paramètre `maintenance_io_concurrency`
  * Permet d'augmenter le nombre d'I/O sur les opérations de maintenance
  * Équivalent à `effective_io_concurrency`

</div>

<div class="notes">

Il s'agit du « nombre de requêtes simultanées que les disques peuvent assurer efficacement
pour les opérations de maintenance »,
<!-- dixit https://git.postgresql.org/gitweb/?p=postgresql.git;a=blob;f=src/backend/access/common/reloptions.c;h=ec207d3b26c0e48a8b581f792bc022ed7249efb6;hb=fc34b0d9de27ab5ac2887da00b3892bdabd89e45 -->
comme le `VACUUM`.
Ce nouveau paramètre a un rôle équivalent à `effective_io_concurrency`,
qui concerne une seule session.
En résumé, il permet d'estimer la capacité à faire des lectures en avance de
phase sur le stockage (_prefetch_).

Le choix de sa valeur peut être délicat.
`effective_io_concurrency` vaut par défaut 1, et s'estime à partir du nombre
de disques (hors ceux de parité) d'une grappe de disques RAID, avec des valeurs de 500 ou plus pour
des SSD (noter que les valeurs de `effective_io_concurrency` doivent être plus élevées
en version 13).
`maintenance_io_concurrency` vaut par défaut 10, donc une valeur nettement supérieure,
car les opérations de maintenance ne sont pas censées être nombreuses en parallèle.
Il faudra donc le changer aussi si `effective_io_concurrency` est modifié.
<!-- et je ne trouve pas de règle plus précise... -->

Comme `effective_io_concurrency`, ce paramètre peut être modifié au niveau
de chaque tablespace avec `ALTER TABLESPACE`, si les caractéristiques physiques diffèrent.

</div>
