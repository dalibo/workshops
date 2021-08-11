<!--

Le commit sur ce sujet est :
https://github.com/postgres/postgres/commit/927474ce1a2498ddb617c6113a88ca61fbba161d

Discussion générale :
https://postgr.es/m/CAEET0ZEffUkXc48pg2iqARQgGRYDiiVxDu+yYek_bTwJF+q=Uw@mail.gmail.com

-->

<div class="slide-content">

* `--write-recovery-conf` permet de générer le fichier `standby.signal` et
  configure la connexion à l'instance primaire dans `postgresql.auto.conf` ;
* nécessite de préciser l'argument `--source-server`

</div>

<div class="notes">

Le nouveau paramètre `-R` ou `--write-recovery-conf` permet de spécifier à
pg_rewind qu'il doit :

* générer le fichier `PGDATA/standby.signal` ;
* ajouter le paramètre `primary_conninfo` au fichier
  `PGDATA/postgresql.auto.conf`.

Ce paramètre nécessite l'utilisation de `--source-server` pour fonctionner. La
chaîne de connexion ainsi spécifiée sera celle utilisée par pg_rewind pour
générer le paramètre `primary_conninfo` dans `PGDATA/postgresql.auto.conf`.
Cela signifie que l'utilisateur sera le même que celui utilisé pour l'opération
de resynchronisation.

</div>
