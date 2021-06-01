#### Authentification SCRAM-SHA-256 par défaut

<div class="slide-content">

Défaut à présent : `password_encryption` = `scram-sha-256`

  * Utilisation conseillée depuis la version 10 !
  * Migration :
    * utilisateur par utilisateur
    * `SET password_encryption TO "scram-sha-256" ;`
    * ré-entrer le mot de passe
    * dans `pg_hba.conf` : `md5` → `scram-sha-256`

</div>

<div class="notes">

L'ancienne méthode de chiffrement MD5 utilisée jusque là par défaut est
obsolète.  Depuis PostgreSQL 10, on pouvait la remplacer par un nouvel
algorithme bien plus sûr : SCRAM-SHA-256.

Il s'agit de l'implémentation du _Salted Challenge Response Authentication
Mechanism_, basé sur un schéma de type question-réponse, qui empêche le
_sniffing_ de mot de passe sur les connexions non fiables.

De plus, un même mot de passe entré deux fois sera stocké différemment, alors
qu'un chiffrement en MD5 sera le même pour un même nom d'utilisateur, même dans
des instances différentes.

Pour plus d'information à ce sujet, vous pouvez consulter [cet article de
Depesz](https://www.depesz.com/2017/04/18/waiting-for-postgresql-10-support-scram-sha-256-authentication-rfc-5802-and-7677/)

Tous les logiciels clients un peu récents devraient être à présent compatibles.
Au besoin, vous pourrez revenir à `md5` pour un utilisateur donné.
Pour passer d'un système de chiffrement à l'autre, il suffit de passer le
paramètre `password_encryption` de `md5` à `scram-sha-256`, globalement ou dans
une session, et de ré-entrer le mot de passe des utilisateurs.  La valeur dans
`postgresql.conf` n'est donc que la valeur par défaut.

**Attention** : Ce paramètre dépend en partie de l'installation. Vérifiez que
`password_encryption` est bien à `scram-sha-256` dans `postgresql.conf` avant
de rentrer des mots de passe.

<!-- Ce qui suit est déjà possible avant la v14, mais c'est maintenant qu'il faut le rappeler -->

Par exemple :
```sql
-- A exécuter en tant que postgres

DROP ROLE pierrot ;
DROP ROLE arlequin ;

CREATE ROLE pierrot LOGIN ;
CREATE ROLE arlequin LOGIN ;

-- Les 2 utilisent le même mot de passe « colombine »

-- pierrot se connecte avec une vieille application
-- qui a besoin d'un mot de passe MD5

SET password_encryption TO md5 ;
\password pierrot

-- arlequin utilise un client récent
SET password_encryption TO "scram-sha-256" ;

\password arlequin

SELECT rolname, rolpassword
FROM   pg_authid
WHERE  rolname IN ('pierrot', 'arlequin') \gx
```
```
-[ RECORD 1 ]-----------------------------------------------------------------------
rolname     | pierrot
rolpassword | md59c20f03b508f8120b2294a8fedd42557
-[ RECORD 2 ]-----------------------------------------------------------------------
rolname     | arlequin
rolpassword | SCRAM-SHA-256$4096:tEblPJ9ZoVPEkE/AOyreag==$cb/g6sak7SDEL6gCxRd9GUH …
```

Le type de mot de passe est visible au début de `rolpassword`.

Noter que si Pierrot utilise le même mot de passe sur une autre instance
PostgreSQL avec le chiffrage MD5, on retrouvera
`md59c20f03b508f8120b2294a8fedd42557`. Cela ouvre la porte à certaines attaques
par force brute, et peut donner la preuve que le mot de passe est identique sur
différentes installations.

Dans `pg_hba.conf`, pour se connecter, ils auront besoin de ces deux lignes :
```ini
host    all             pierrot           192.168.88.0/24           md5
host    all             arlequin          192.168.88.0/24           scram-sha-256
```
(Ne pas oublier de recharger la configuration.)

Puis Pierrot met à jour son application. Son administrateur ré-entre alors le
même mot de passe avec SCRAM-SHA-256 :

```sql
-- A exécuter en tant que postgres

SET password_encryption TO "scram-sha-256" ;

\password pierrot

SELECT rolname, rolpassword
FROM   pg_authid
WHERE  rolname IN ('pierrot', 'arlequin') \gx
```
```
-[ RECORD 1 ]-----------------------------------------------------------------------
rolname     | arlequin
rolpassword | SCRAM-SHA-256$4096:tEblPJ9ZoVPEkE/AOyreag==$cb/g6sak7SDEL6gCxRd9GUH …
-[ RECORD 2 ]-----------------------------------------------------------------------
rolname     | pierrot
rolpassword | SCRAM-SHA-256$4096:fzKspWtDmyFKy3j+ByXvhg==$LfM08hhV3BYgqubxZJ1Vkfh …
```

Pierrot peut se reconnecter tout de suite sans modifier `pg_hba.conf` : en
effet,  une entrée `md5` autorise une connexion par SCRAM-SHA-256 (l'inverse
n'est pas possible).

Par sécurité, après validation de l'accès, il vaut mieux ne plus accepter que
SCRAM-SHA-256 dans `pg_hba.conf` :

```ini
host    all             pierrot           192.168.88.0/24           scram-sha-256
host    all             arlequin          192.168.88.0/24           scram-sha-256
```

</div>
