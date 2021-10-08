<!--
Les commits sur ce sujet sont :

* https://git.postgresql.org/gitweb/?p=postgresql.git;a=commit;h=6c3ffd697e2242f5497ea4b40fffc8f6f922ff60
* https://git.postgresql.org/gitweb/?p=postgresql.git;a=commit;h=a14a0118a1fecf4066e53af52ed0f188607d0c4b

Discussion

* https://gitlab.dalibo.info/formation/workshops/-/issues/99

-->

## Découvrir les nouveaux rôles prédéfinis

<div class="slide-content">
* Utiliser le rôle `pg_database_owner` dans une base _template_
* Exporter avec le rôle `pg_read_all_data`
* Importer avec le rôle `pg_write_all_data`
</div>

<div class="notes">

### Utiliser le rôle `pg_database_owner` dans une base _template_

* Avec le compte `postgres`, créer une nouvelle base modèle `tp1_template` à
  l'aide de la commande `createdb` ou l'instruction `CREATE DATABASE`.

```sh
createdb -e tp1_template
```
```sql
CREATE DATABASE tp1_template;
```

* Se connecter à cette nouvelle base et y ajouter une table `members` avec les
  trois colonnes comme suit :

```sh
psql -U postgres -d tp1_template
```
```sql
CREATE TABLE members (
  id int PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
  name varchar(25),
  age int CHECK (age > 0)
);
```

Par défaut, le propriétaire d'un objet correspond au rôle qui le créé dans la
base, en l'occurrence le rôle `postgres` dans notre exemple. La commande `\d`
de l'outil `psql` permet de lister les tables, vues et séquences présentes dans
les schémas courants de l'utilisateur.

```text
tp1_template=# \d
               List of relations
 Schema |      Name      |   Type   |  Owner   
--------+----------------+----------+----------
 public | members        | table    | postgres
 public | members_id_seq | sequence | postgres
```

* Modifier le propriétaire des objets avec le nouveau rôle `pg_database_owner`.

```sql
ALTER TABLE members OWNER TO pg_database_owner;
```
```text
tp1_template=# \d
                   List of relations
 Schema |      Name      |   Type   |       Owner       
--------+----------------+----------+-------------------
 public | members        | table    | pg_database_owner
 public | members_id_seq | sequence | pg_database_owner
```

* Créer un utilisateur `atelier`, ainsi qu'une nouvelle base `tp1` basée sur le
  modèle `tp1_template`, dont il sera propriétaire. Ajouter son mot de passe 
  dans le fichier `.pgpass` pour simplifier l'authentification.

```sh
createuser --pwprompt atelier
createdb -e --owner=atelier --template=tp1_template tp1

echo 'localhost:5432:tp1:*:p@ssword' > ~/.pgpass
chmod 600 ~/.pgpass
```

* Quel est le propriétaire des objets présents dans la base `tp1` ?

Les droits sont similaires à la base modèle, notamment le propriétaire
`pg_database_owner` sur les objets `members` et `members_id_seq`.

```
tp1=> \d
                   List of relations
 Schema |      Name      |   Type   |       Owner       
--------+----------------+----------+-------------------
 public | members        | table    | pg_database_owner
 public | members_id_seq | sequence | pg_database_owner
```

* Se connecter à la base `tp1` avec le rôle propriétaire `atelier` et ajouter
  quelques lignes dans la table `members`.

```sh
psql -h localhost -U atelier tp1
```
```sql
INSERT INTO members (name, age) VALUES 
  ('Jean', 41),
  ('John', 38),
  ('Jessica', 26);
```
```text
INSERT 0 3
```

Sans être explicitement autorisé à écrire dans la table `members`, le rôle 
`atelier` bénéficie de tous les droits des objets appartenant au rôle 
`pg_database_owner` en sa qualité de propriétaire de la base de données.

### Exporter avec le rôle `pg_read_all_data`

* Créer un nouvel utilisateur `dump_user` et tenter d'exporter les données de la
  base `atelier` avec l'outil `pg_dump`. Que se passe-t-il ?

```sh
createuser --pwprompt dump_user
pg_dump -h localhost -U dump_user -d tp1 > dump_tp1.sql
```
```text
pg_dump: error: query failed: ERROR:  permission denied for table members
pg_dump: error: query was: LOCK TABLE public.members IN ACCESS SHARE MODE
```

* Recommencer l'export après lui avoir assignaer les droits du rôle `pg_read_all_data`.
  Ce droit doit être octroyé par un superutilisateur comme `postgres`.

```sh
psql -U postgres
```
```sql
GRANT pg_read_all_data TO dump_user;
```

Il est alors possible pour l'utilisateur `dump_user` de sauvegarder la base de 
données `tp1`.

```sh
pg_dump -h localhost -U dump_user -d tp1 > dump_tp1.sql
```
```sql
--
-- PostgreSQL database dump
--

--
-- Name: members; Type: TABLE; Schema: public; Owner: atelier
--

CREATE TABLE public.members (
    id integer NOT NULL,
    name character varying(25),
    age integer,
    CONSTRAINT members_age_check CHECK ((age > 0))
);

ALTER TABLE public.members OWNER TO atelier;

--
-- Name: members_id_seq; Type: SEQUENCE; Schema: public; Owner: atelier
--

ALTER TABLE public.members ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME public.members_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);

--
-- Data for Name: members; Type: TABLE DATA; Schema: public; Owner: atelier
--

COPY public.members (id, name, age) FROM stdin;
1	Jean	41
2	John	38
3	Jessica	26
\.

--
-- Name: members_id_seq; Type: SEQUENCE SET; Schema: public; Owner: atelier
--

SELECT pg_catalog.setval('public.members_id_seq', 3, true);

--
-- Name: members members_pkey; Type: CONSTRAINT; Schema: public; Owner: atelier
--

ALTER TABLE ONLY public.members
    ADD CONSTRAINT members_pkey PRIMARY KEY (id);

--
-- PostgreSQL database dump complete
--
```

* Exporter les données globales de l'instance à l'aide de l'outil `pg_dumpall` et
  le compte `dump_user`.

```sh
pg_dumpall -h localhost -U dump_user --globals-only > dump_tp1_globals.sql
```
```sql
--
-- PostgreSQL database cluster dump
--

--
-- Roles
--

CREATE ROLE atelier;
ALTER ROLE atelier 
 WITH NOSUPERUSER INHERIT NOCREATEROLE NOCREATEDB LOGIN NOREPLICATION NOBYPASSRLS 
 PASSWORD 'SCRAM-SHA-256$:xxx';
CREATE ROLE postgres;
ALTER ROLE postgres
 WITH SUPERUSER INHERIT CREATEROLE CREATEDB LOGIN REPLICATION BYPASSRLS;
CREATE ROLE dump_user;
ALTER ROLE dump_user
 WITH NOSUPERUSER INHERIT NOCREATEROLE NOCREATEDB LOGIN NOREPLICATION NOBYPASSRLS
 PASSWORD 'SCRAM-SHA-256$xxx';

--
-- Role memberships
--

GRANT pg_read_all_data TO dump_user GRANTED BY postgres;

--
-- PostgreSQL database cluster dump complete
--
```

Le compte `dump_user` est bien adapté pour les exports multiples à l'aide
de la commande `pg_dumpall` ou pour des logiciels plus complets comme [pg_back].

[pg_back]: https://github.com/orgrim/pg_back

----

### Importer avec le rôle `pg_write_all_data`

* Créer un nouveau rôle `load_user` et lui affecter les rôles `pg_write_all_data`.
  Ce droit doit être octroyé par un superutilisateur comme `postgres`.

```sh
psql -U postgres
```
```sql
CREATE ROLE load_user WITH LOGIN;
\password load_user
GRANT pg_write_all_data TO load_user;
```

* Créer un fichier `members.csv` sur le disque et y ajouter les lignes suivantes.

```text
id,name,age
1,Jean,41
2,John,38
3,Jessica,26
4,Johnny,74
5,Joe,55
6,Jennifer,33
7,Jerôme,40
8,Jenny,21
9,Jesus,33
10,Jérémie,12
```

* Se reconnecter avec ce nouveau rôle et tenter de lire les données de la table
  `members` dans la base `tp1`.

```sql
\c 'host=localhost user=load_user dbname=tp1'
SELECT id, name, age FROM members LIMIT 10;
```
```text
ERROR:  permission denied for table members
```

* Charger les données du fichier `.csv` dans la table `members` avec l'utilisateur
  `load_user` et la méthode `\copy` de l'outil `psql`.

```sql
\copy members FROM 'members.csv' WITH DELIMITER ',' CSV HEADER;
```
```text
ERROR:  duplicate key value violates unique constraint "members_pkey"
CONTEXT:  COPY members, line 2
```

Le chargement tombe en erreur car les premières lignes de la table entre en
conflit sur la contrainte de clé primaire. Il est nécessaire d'enrichir le 
traitement d'import avec une gestion d'erreurs ou une solution plus complexe
que l'instruction `COPY`.

* Créer une copie de la table `members` sans les données et charger les données
  du fichier `.csv`.

```sql
CREATE TABLE members_copy AS TABLE members WITH NO DATA;
\copy members_copy FROM 'members.csv' WITH DELIMITER ',' CSV HEADER;
```

* Tenter de charger les données de la table `members_copy` avec l'ordre
  `INSERT ON CONFLICT` vers la table finale `members`.

```sql
INSERT INTO members OVERRIDING SYSTEM VALUE
SELECT id, name, age FROM members_copy
    ON CONFLICT (id) DO NOTHING;
```
```text
ERROR:  permission denied for table members
```

La clause `ON CONFLICT` suppose que l'utilisateur dispose des droits de lecture 
sur la table cible afin de comparer les données de la colonne `id` avant 
l'insertion. Cette méthode n'est donc pas adaptée.

* Réaliser une boucle avec une gestion d'erreurs pour ignorer les données déjà
  présentes dans la table cible `members`.

```sql
DO $$
DECLARE
  m RECORD;
BEGIN
  FOR m IN (SELECT id, name, age FROM members_copy) LOOP
    BEGIN
      INSERT INTO members (id, name, age) OVERRIDING SYSTEM VALUE
      VALUES (m.id, m.name, m.age);
    EXCEPTION 
      WHEN unique_violation THEN null;
    END;
  END LOOP;
END;
$$;
```

Une autre solution, plus rapide, serait de supprimer le contenu de la table
`members` avec un `DELETE` et de réaliser le chargement par `COPY`. Cependant,
cela nécessite une bonne connaissance du modèle de données, notamment celle des
contraintes de clés étrangères et des suppressions en cascade.

</div>
