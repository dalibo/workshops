<!--

Commit :


-->

<div class="slide-content">

* possibilité de créer des déclencheurs `BEFORE` sur les tables partitionnées.

</div>

<div class="notes">

La version 11 de PostgreSQL a permis d'ajouter le support des déclencheurs sur
les tables partitionnées … à l'exception des déclencheurs `BEFORE`. Ces
derniers devaient donc être créés manuellement sur les partitions.

Avec la version 13, l'ajout d'un déclencheur `BEFORE` sur une table
partitionnée permet de créer automatiquement les déclencheurs sur les partitions
associées. Il y a cependant une limitation : ces déclencheurs  ne peuvent pas
changer la partition cible d'une ligne.


Voici un exemple de ce que l'on peut voir quand on affiche les détails d'une
table partitionnée :

```
\d+ log

                   Partitioned table "public.log"
...
Triggers:
   log_user BEFORE INSERT ON log FOR EACH ROW EXECUTE FUNCTION log_user()
Partitions:
   log_202011 FOR VALUES FROM ('2020-11-01 00:00:00') TO ('2020-12-01 00:00:00'),
   log_202012 FOR VALUES FROM ('2020-12-01 00:00:00') TO ('2021-01-01 00:00:00')

\d log_202011
                     Table "public.log_202011"
...
Partition of: log FOR VALUES FROM ('2020-11-01 00:00:00') TO ('2020-12-01 00:00:00')
Triggers:
   log_user BEFORE INSERT ON log_202011 FOR EACH ROW EXECUTE FUNCTION log_user(),
                ON TABLE log
```

</div>
