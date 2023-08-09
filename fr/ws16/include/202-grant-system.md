<!--
Les sources pour ce sujet sont :

* https://git.postgresql.org/gitweb/?p=postgresql.git;a=commit;h=ce6b672e4

Discussion :

* http://postgr.es/m/CA+TgmoaFr-RZeQ+WoQ5nKPv97oT9+aDgK_a5+qWHSgbDsMp1Vg@mail.gmail.com
-->

<div class="slide-content">

* Améliorations sur le droit `ADMIN OPTION`
* Retourne une erreur s'il est réappliqué au donneur du droit
* `REVOKE ADMIN OPTION ... CASCADE`

</div>

<div class="notes">

La déléguation de droits correspond à la capacité pour un utilisateur d'attribuer à
un autre utilisateur un droit qu'on lui aurait octroyé avec la clause `ADMIN
OPTION`. Dans les versions précédentes, la table `pg_auth_members` ne permettait
pas de gérer plusieurs donneurs d'un même droit à un même utilisateur.

Ainsi, lorsqu'un utilisateur se voyait octroyer un droit avec l'option `ADMIN`,
il ne lui était pas interdit de retirer ce droit à celui qui le lui avait donné,
sans avoir besoin d'être superutilisateur.

```sql
v15=# CREATE ROLE role_adm;
v15=# GRANT role_adm TO user1 WITH ADMIN OPTION;
GRANT ROLE

v15=# SET ROLE = user1;
v15=> GRANT role_adm TO user2 WITH ADMIN OPTION;
GRANT ROLE
v15=> SELECT member::regrole, grantor::regrole, admin_option FROM pg_auth_members WHERE roleid = 'role_adm'::regrole;
 member | grantor  | admin_option
--------+----------+--------------
 user1  | postgres | t
 user2  | user1    | t

v15=> SET ROLE = user2;
v15=> REVOKE ADMIN OPTION FOR role_adm FROM user1;
REVOKE ROLE
v15=> SELECT member::regrole, grantor::regrole, admin_option FROM pg_auth_members WHERE roleid = 'role_adm'::regrole;
 member | grantor  | admin_option
--------+----------+--------------
 user2  | user1    | t
 user1  | postgres | f
(2 rows)

v15=> SET ROLE = user1;
v15=> GRANT role_adm TO user3;
ERROR:  must have admin option on role "role_adm"
```

On constate que la ligne de la table `pg_auth_members` a été modifiée avec le
changement de la colonne `admin_option` passée de `true` à `false` alors même
que ce droit `ADMIN` lui avait été octroyé par un rôle plus puissant que `user2`.
La version 16 étend la contrainte d'unicité de la table `pg_auth_members` à la
colonne `grantor`. Ainsi, un `REVOKE` par un tiers ne supprimera pas la
délégation d'un droit entre deux autres rôles.

```sql
v16=> SET ROLE = user2;
v16=> REVOKE ADMIN OPTION FOR role_adm FROM user1;
REVOKE ROLE
v16=> SELECT member::regrole, grantor::regrole, admin_option FROM pg_auth_members WHERE roleid = 'role_adm'::regrole;
 member | grantor  | admin_option
--------+----------+--------------
 user1  | postgres | t
 user2  | user1    | t
 user1  | user2    | f

v16=> SET ROLE = user1;
v16=> GRANT role_adm TO user3;
GRANT ROLE
```

Ce changement a également été l'occasion d'enrichir les exceptions possibles
inhérentes à la relation de délégation entre plusieurs rôles. L'exemple
ci-dessous montre qu'un rôle ne peut pas réattribuer un droit `ADMIN` à son
propre donneur.

```sql
v16=# CREATE ROLE role_adm;
v16=# GRANT role_adm TO user1 WITH ADMIN OPTION;
GRANT ROLE

v16=# SET ROLE = user1;
v16=> GRANT role_adm TO user2 WITH ADMIN OPTION;

v16=> SET ROLE = user2;
v16=> GRANT role_adm TO user1 WITH ADMIN OPTION;
ERROR:  ADMIN option cannot be granted back to your own grantor
```

Ce comportement était permis avant la version 16 et renvoyait simplement un
avertissement.

```sql
v15=# SET ROLE = user2;
v15=> GRANT role_adm TO user1 WITH ADMIN OPTION;
NOTICE:  role "user1" is already a member of role "role_adm"
GRANT ROLE
```

Puisque la notion de donneur est maintenue entre plusieurs niveaux hiérarchiques
de rôles, la nouvelle version permet d'empêcher la révocation d'un droit lorsque
celui-ci a été octroyé à d'autres utilisateurs. L'exemple suivant montre qu'une
erreur est renvoyée au client avec pour conseil d'utiliser l'instruction `REVOKE
... CASCADE`.


```sql
v16=# GRANT role_adm TO user1 WITH ADMIN OPTION;
v16=# GRANT role_adm TO user2 WITH ADMIN OPTION GRANTED BY user1;

v16=# SELECT member::regrole, grantor::regrole, admin_option FROM pg_auth_members WHERE roleid = 'role_adm'::regrole;
 member | grantor  | admin_option
--------+----------+--------------
 user1  | postgres | t
 user2  | user1    | t

v16=# REVOKE ADMIN OPTION FOR role_adm FROM user1;
ERROR:  dependent privileges exist
HINT:  Use CASCADE to revoke them too.

v16=# REVOKE ADMIN OPTION FOR role_adm FROM user1 CASCADE;
REVOKE ROLE

v16=# SELECT member::regrole, grantor::regrole, admin_option FROM pg_auth_members WHERE roleid = 'role_adm'::regrole;
 member | grantor  | admin_option
--------+----------+--------------
 user1  | postgres | f
```

Ainsi, le rôle `user1` dispose encore du droit octroyé par `postgres` mais n'est
plus en capacité de le donner à d'autres utilisateurs. L'action `REVOKE...
CASCADE` est rétroactive, avec le retrait définitif des droits pour les rôles
qui en ont bénéficié (ici, `user2` n'a plus le droit que `user1` lui a donné). Dans
les versions précédentes, une telle opération aboutissait et l'utilisateur
intermédiare ne disposait plus de son droit `ADMIN`, sans que cela ne retire le
moindre droit aux rôles en bas de la hiérarchie.

```sql
v15=# SELECT member::regrole, grantor::regrole, admin_option FROM pg_auth_members WHERE roleid = 'role_adm'::regrole;
 member | grantor  | admin_option
--------+----------+--------------
 user1  | postgres | t
 user2  | user1    | t
 user3  | user2    | t

v15=# REVOKE ADMIN OPTION FOR role_adm FROM user1;
REVOKE ROLE

v15=# SELECT member::regrole, grantor::regrole, admin_option FROM pg_auth_members WHERE roleid = 'role_adm'::regrole;
 member | grantor  | admin_option
--------+----------+--------------
 user2  | user1    | t
 user3  | user2    | t
 user1  | postgres | f
```

</div>
