<!--
Les commits sur ce sujet sont :

* pgsql: Add new predefined role pg_create_subscription.
  https://www.postgresql.org/message-id/E1phuke-000Ukd-IP@gemulon.postgresql.org
* pgsql: Improve error message for pg_create_subscription.
  https://www.postgresql.org/message-id/E1pxaAM-001pcI-Qh@gemulon.postgresql.org

Discussion :

* https://www.postgresql.org/message-id/flat/CA%2BTgmoaDH%3D0Xj7OBiQnsHTKcF2c4L%2B%3DgzPBUKSJLh8zed2_%2BDg%40mail.gmail.com#a6bd2df792d2a61cbe5a5a7757bf48e8

-->

<div class="slide-content">

 * Nouveau rôle `pg_create_subscription`
   + prévenir des failles de sécurité
 * Droit `CREATE` sur la base de données pour
     + `ALTER SUBSCRIPTION .. RENAME`
     + `ALTER SUBSCRIPTION .. OWNER TO`
 * Mot de passe défini et utilisé lors de l'authentification
 * Paramètre de souscription : `require_pasword`

</div>

<div class="notes">

Le rôle `pg_create_subscription` peut être donné à des utilisateurs ne
bénéficiant pas de l'attribut `SUPERUSER` afin qu'ils puissent exécuter la
commande `CREATE SUBSCRIPTION`. En plus de ce groupe, l'utilisateur doit avoir
la permission `CREATE` sur la base de données où la souscription va être créée.
Les commandes `ALTER SUBSCRIPTION .. RENAME` et `ALTER SUBSCRIPTION .. OWNER
TO` nécessitent aussi ce privilège sur la base de données. Les autres versions
de la commande `ALTER SUBSCRIPTION` nécessitent uniquement d'être le
propriétaire de l'objet.

<!--
https://www.postgresql.org/message-id/00B83B73-C9C3-487B-89F8-BA810BC38CBF%40enterprisedb.com

The issue that gets thrown around in the email archive is that "arbitrary code"
can be made to run on the subscriber side.  As I understand the problem, this
is because trigger functions can be created on tables with arbitrary code in
them, and that code will be executed under the userid of the user who causes
the trigger to fire during an insert/update/delete rather than as the user who
created the trigger.  This of course is not peculiar to logical replication; it
is how triggers work generally.  What is peculiar is that a non-superuser who
can create tables, triggers, publications and subscriptions can get the logical
replication worker to perform inserts/updates/deletes on those tables, thereby
firing those triggers, and executing the trigger code as superuser.  That is
ordinarily not something that a user can do simply by creating a table with a
trigger, since there would be no mechanism to force the superuser to perform
operations on the table.

-->

La raison de l'ajout de ce nouveau rôle est de prévenir des failles de
sécurité où un utilisateur sans privilège pourrait exécuter du code en tant
que super utilisateur en utilisant la réplication logique. L'origine du
problème est liée à l'utilisation des _triggers_. Ils permettent d'exécuter du
code en utilisant le _userid_ de l'utilisateur qui déclenche le _trigger_
plutôt que celui de l'utilisateur qui a créé le _trigger_. Un utilisateur qui a
le droit de créer des tables, triggers, publications et souscriptions pourrait
faire en sorte qu'un _logical replication worker_ réalise des `INSERT`,
`UPDATE` ou `DELETE` qui déclencheraient alors les _triggers_ qui
s'exécuteraient en tant que super utilisateur.

Afin de tester cette nouvelle fonctionnalité, créons une publication sur un
premier serveur.

```sql
CREATE DATABASE tests_pg16;
\c tests_pg16 -
CREATE TABLE matable(i int);
CREATE ROLE user_pub_pg16 WITH LOGIN REPLICATION PASSWORD 'repli';
GRANT SELECT ON TABLE matable TO user_pub_pg16;
CREATE PUBLICATION pub_pg16 FOR TABLE matable;
```

On peut maintenant créer la souscription sur le serveur en version 16.

```sql
CREATE DATABASE tests_pg16;
CREATE ROLE sub_owner WITH LOGIN;
GRANT pg_create_subscription TO sub_owner ;
\c tests_pg16 -
GRANT CREATE, USAGE ON SCHEMA public TO sub_owner;
\c tests_pg16 sub_owner ;
CREATE TABLE matable(i int);
CREATE SUBSCRIPTION sub_pg16
       CONNECTION 'host=/var/run/postgresql port=5437 user=user_pub_pg16 dbname=tests_pg16'
       PUBLICATION pub_pg16;
```

Comme promis, la création de la souscription est impossible sans avoir la
permission `CREATE` sur la base `tests_pg16`.

```console
ERROR:  permission denied for database tests_pg16
```

Une fois la permission donnée avec l'utilisateur **postgres**:

```sql
\c tests_pg16 postgres
GRANT CREATE ON DATABASE tests_pg16 TO sub_owner;
```

... une nouvelle subtilité de cette mise à jour pointe son nez.

```console
ERROR:  password is required
DETAIL:  Non-superusers must provide a password in the connection string.
```

En effet, les utilisateurs ne bénéficiant pas de l'attribut `SUPERUSER` doivent
fournir un mot de passe lors de la création de la souscription avec le mot clé
`password` de la chaine de connexion.

```sql
\c tests_pg16 sub_owner
CREATE SUBSCRIPTION sub_pg16
       CONNECTION 'host=/var/run/postgresql port=5437 user=user_pub_pg16 dbname=tests_pg16 password=repli'
       PUBLICATION pub_pg16;
```

Cette modification ne suffit pas, il faut également configurer la méthode
d'authentification de sorte que le mot de passe soit utilisé lors de la
connexion. Dans le cas contraire, on se voit gratifier du message suivant :

```console
ERROR:  password is required
DETAIL:  Non-superuser cannot connect if the server does not request a password.
HINT:  Target server's authentication method must be changed, or set password_required=false in the subscription parameters.
```

Pour ce test, la ligne suivante doit être ajoutée au début du `pg_hba.conf` de
l'instance portant la publication et la configuration rechargée :

```console
local   tests_pg16      user_pub_pg16                           scram-sha-256
```

La commande précédente peut désormais s'exécuter sans erreur :

```sql
CREATE SUBSCRIPTION sub_pg16
       CONNECTION 'host=/var/run/postgresql port=5437 user=user_pub_pg16 dbname=tests_pg16 password=repli'
       PUBLICATION pub_pg16;
```
```console
NOTICE:  created replication slot "sub_pg16" on publisher
CREATE SUBSCRIPTION
```

Il est possible de faire en sorte qu'un utilisateur n'ayant pas l'attribut
SUPERUSER soit propriétaire de la souscription sans fournir de mot de passe, en
la créant avec l'attribut `password_required=false`. L'utilisation de cet
attribut requiert d'être SUPERUSER.

```sql
\c tests_pg16 postgres
DROP SUBSCRIPTION sub_pg16;
CREATE SUBSCRIPTION sub_pg16
       CONNECTION 'host=/var/run/postgresql port=5437 user=user_pub_pg16 dbname=tests_pg16'
       PUBLICATION pub_pg16
       WITH (password_required=false);
ALTER SUBSCRIPTION sub_pg16 OWNER TO sub_owner;
```
```console
NOTICE:  created replication slot "sub_pg16" on publisher
CREATE SUBSCRIPTION
ALTER SUBSCRIPTION
```

Dans ce cas l'utilisateur **sub_owner** ne peut pas modifier la souscription :

```sql
\c tests_pg16 sub_owner
ALTER SUBSCRIPTION sub_pg16 DISABLE;
```
```console
ERROR:  password_required=false is superuser-only
HINT:  Subscriptions with the password_required option set to false may only be created or modified by the superuser.
```

La seule action possible est le `DROP SUBSCRIPTION` :

```sql
DROP SUBSCRIPTION sub_pg16;
```
```console
NOTICE:  dropped replication slot "sub_pg16" on publisher
DROP SUBSCRIPTION
```

La valeur par défaut de l'option `password_required` est `true`. Le paramétrage
est ignoré pour un utilisateur bénéficiant de l'attribut SUPERUSER. Il est par
conséquent possible de créer une souscription avec `password_required=true` et
de la transférer à un utilisateur ne bénéficiant pas de l'attribut SUPERUSER.
Dans ce cas, le comportement de la souscription est instable. Ce genre de
manipulation est donc déconseillé.

</div>
