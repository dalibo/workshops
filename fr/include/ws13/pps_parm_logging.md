<!--
Les commits sur ce sujet sont :

* https://git.postgresql.org/gitweb/?p=postgresql.git;a=commitdiff;h=0b34e7d307e6a142ee94800e6d5f3e73449eeffd
* https://git.postgresql.org/gitweb/?p=postgresql.git;a=commitdiff;h=ba79cb5dc841104cf4810b5c23af4f881079dbb5

Discussion générale:

* https://postgr.es/m/b10493cc-a399-a03a-67c7-068f2791ee50@imap.cc
* https://postgr.es/m/0146a67b-a22a-0519-9082-bc29756b93a2@imap.cc

-->

<div class="slide-content">

* `log_parameter_max_length` permet de définir le volume de paramètres maximal
   associé aux requêtes préparées dans les traces ;
* ces valeurs sont notamment associées à leur requête préparée par les
  paramètres `log_min_duration_statements` ou `log_min_duration_sample` ;
* `log_parameter_max_length_on_error` permet de définir le volume de paramètres
  maximal affiché dans les traces des requêtes préparées à cause d'erreurs.

</div>

<div class="notes">

Deux nouveaux paramètres GUC ont été ajoutés pour contrôler l'affichage des
paramètres associés (_bind_) aux requêtes préparées dans les traces de
PostgreSQL.

`log_parameter_max_length` s'applique aux requêtes préparées tracées grâce à des
paramètres comme `log_min_duration_statement` et `log_min_duration_sample`. Par
défaut, ils sont affichés dans leur intégrité (valeur `-1` du paramétrage). Il
est également possible de désactiver complètement leur affichage avec la valeur
0 ou de spécifier une limite en octet. Ce paramètre ne nécessite pas de
redémarrage pour être modifié. En revanche, il faut employer un utilisateur
bénéficiant de l'attribut `SUPERUSER` pour le faire au sein d'une session.

`log_parameter_max_length_on_error` concerne les requêtes préparées écrites
dans les traces à cause d'erreurs. Par défaut, l'affichage de leurs paramètres
est désactivé (valeur `0`). Cela peut être modifié à chaud par n'importe quel
utilisateur, dans sa session, en spécifiant une taille en octet ou `-1` pour
tout afficher.

Le comportement par défaut correspond à celui observable sur la version
précédente de PostgreSQL.

Exemple :

```
$ cat ~/tmp/bench.script
SET log_parameter_max_length_on_error TO -1;
SET log_parameter_max_length TO 5;
SET log_min_duration_statement TO 1500;

\SET one 0123456789

SELECT pg_sleep(2), :one, 'logged';
SELECT pg_sleep(1), :one, 'not logged';
SELECT 1/0, :one, 'logged';

$ pgbench -c1 -t1 -M prepared -n -f ~/tmp/bench.script
```

Produit les traces :

```
LOG:  duration: 2002.175 ms  execute <unnamed>: SELECT pg_sleep(2), $1, 'logged';
DETAIL:  parameters: $1 = '12345...'
ERROR:  division by zero
CONTEXT:  unnamed portal with parameters: $1 = '123456789'
STATEMENT:  SELECT 1/0, $1, 'logged';
```

</div>
