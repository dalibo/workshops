<!--
Les commits sur ce sujet sont :

* https://git.postgresql.org/gitweb/?p=postgresql.git;a=commit;h=92bf7e2d027466d750b4ac5b026f6f4ac29be881

Discussion

* https://www.postgresql.org/message-id/flat/0DDF369B45A1B44B8A687ED43F06557C010BC362@G01JPEXMBYT03

-->

<div class="slide-content">
```
CREATE OR REPLACE TRIGGER check_update
  BEFORE UPDATE OF balance ON accounts
  FOR EACH ROW
  EXECUTE FUNCTION check_account_update();
```

* Ne fonctionne pas pour les `CONSTRAINT TRIGGER`
* Ne pas lancer dans une transaction qui a modifié la table du trigger

</div>

<div class="notes">

La syntaxe `OR REPLACE` est désormais disponible dans l'ordre de création des
triggers. C'est une extension du standard SQL qui permet de mettre à jour la
définition d'un trigger sans devoir le supprimer au préalable.

Cette fonctionnalité n'est pas disponible pour les triggers de type
[`CONSTRAINT
TRIGGER`](https://www.postgresql.org/docs/14/sql-createtrigger.html) et
provoque le message d'erreur suivant.

```
ERROR:  CREATE OR REPLACE CONSTRAINT TRIGGER is not supported
```

De plus, si des instructions ont mis à jour la table sur laquelle le trigger est
placé,  il est déconseillé d'exécuter le `CREATE OR REPLACE` dans la même
transaction. En effet, le résultat pourrait être différent de ce que vous
anticipez.

</div>
