<!--
Les commits sur ce sujet sont :

* https://git.postgresql.org/gitweb/?p=postgresql.git;a=commit;h=344d62fb9a978a72cf8347f0369b9ee643fd0b31

Discussion

* https://gitlab.dalibo.info/formation/workshops/-/issues/164

-->

<div class="slide-content">

* Evite de répliquer une séquence d'une table `unlogged`
* Pas dans un but de performance
* Une séquence d'identité hérite automatiquement de la persistance de la table de référence

</div>

<div class="notes">

Il est maintenant possible de définir une séquence comme non journalisée (`unlogged`). Contrairement 
aux tables, cette option n'est pas destinée à améliorer les performances mais principalement à éviter de 
répliquer des objets inutilement.

Dorénavent, une séquence identitaire hérite automatiquement de la persistance de la table dont elle dépend.

```sql
# En version 14
postgres=# create unlogged table journal (id integer GENERATED ALWAYS AS IDENTITY);
CREATE TABLE

# Vérifions la persistance de la séquence associée
postgres=# \ds+
                                    Liste des relations
 Schéma |      Nom       |   Type   | Propriétaire | Persistence |   Taille   | Description 
--------+----------------+----------+--------------+-------------+------------+-------------
 public | journal_id_seq | séquence | postgres     | permanent   | 8192 bytes | 

# En version 15
postgres=# create unlogged table journal (id integer GENERATED ALWAYS AS IDENTITY);
CREATE TABLE

# Vérification de la persistance
postgres=# \ds+
                                    Liste des relations
 Schéma |      Nom       |   Type   | Propriétaire |  Persistence   | Taille | Description 
--------+----------------+----------+--------------+----------------+--------+-------------
 public | journal_id_seq | séquence | postgres     | non journalisé | 16 kB  | 
```

Il est également possible de définir manuellement une séquence comme `unlogged` avec les commandes suivantes :

```sql
CREATE UNLOGGED SEQUENCE ma_seq;
ALTER SEQUENCE ma_seq SET LOGGED|UNLOGGED;
```

Enfin, la persistance des séquences est concervée lors des opération d'export / import avec des outils 
comme `pg_dump` et `pg_restore`.

</div>
