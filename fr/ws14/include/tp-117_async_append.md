## Mise en place d'un sharding minimal

<div class="slide-content">
  
* Préparer le modèle et configurer les accès distants
* Alimenter une table partitionnée répartie dans plusieurs bases de données
* Étudier les différents cas d'usage

</div>

<div class="notes">

Dans cet exercice, nous visons à mettre en place une architecture distribuée,
dites de _sharding_, à travers une table partitionnée dont les lignes sont
réparties entre plusieurs tables distantes. Cette répartition doit être longuement
étudiée, car la clé et la méthode de partitionnement sont cruciales lors de
l'élaboration du modèle de données.

<!-- https://www.digitalocean.com/community/tutorials/understanding-database-sharding -->

Nous prenons l'exemple d'une table de recensement de la population française,
répartie selon les dix-huit subdivisions régionales, telles qu'établies depuis
le 1er janvier 2016. Cette table a vocation de contenir des données démographiques
anonymisées, telles que la date et la région de naissance, voire la date de décès
si survenu.

<!-- https://fr.wikipedia.org/wiki/R%C3%A9gion_fran%C3%A7aise -->

### Préparer le modèle de données

* Créer la base `region_template`. Ce _template_ permet de recréer le modèle à
  l'identique dans une nouvelle base sur la même instance par soucis de
  simplicité.

```sql
CREATE DATABASE region_template WITH IS_TEMPLATE = true;
```

* Créer dans ce _template_ la table `regions` avec les correspondances des 
  régions administratives.

L'identifiant de région correspond aux codes issus de la norme [ISO 3166-2] et
sera stocké dans un champ texte de six caractères.

[ISO 3166-2]: https://fr.wikipedia.org/wiki/ISO_3166-2:FR

```sql
\c region_template

CREATE TABLE regions (
  region_id varchar(6) PRIMARY KEY,
  region text
);

INSERT INTO regions VALUES 
  ('FR-ARA', 'Auvergne-Rhône-Alpes'), ('FR-BFC', 'Bourgogne-Franche-Comté'),
  ('FR-BRE', 'Bretagne'), ('FR-CVL', 'Centre-Val de Loire'),
  ('FR-COR', 'Corse'), ('FR-GES', 'Grand Est'),
  ('FR-GUA', 'Guadeloupe'), ('FR-GUF', 'Guyane'),
  ('FR-HDF', 'Hauts-de-France'), ('FR-IDF', 'Île-de-France'),
  ('FR-LRE', 'La Réunion'), ('FR-MTQ', 'Martinique'),
  ('FR-MAY', 'Mayotte'), ('FR-NOR', 'Normandie'),
  ('FR-NAQ', 'Nouvelle-Aquitaine'), ('FR-OCC', 'Occitanie'),
  ('FR-PDL', 'Pays de la Loire'), ('FR-PAC', 'Provence-Alpes-Côte d''Azur');
```

* Ajouter la table `population` avec les champs souhaités pour le recensement et
  la contrainte de clé étrangère avec la table `regions`.

```sql
CREATE TABLE population (
  anon_id uuid DEFAULT gen_random_uuid(),
  region_naissance_id varchar(6) NOT NULL,
  date_naissance date NOT NULL,
  date_deces date,
    PRIMARY KEY (anon_id, region_naissance_id),
    FOREIGN KEY (region_naissance_id) REFERENCES regions (region_id)
);
```

L'identifiant `anon_id` est de type `uuid` pour obtenir une valeur unique quelle que 
soit l'instance, alternative indispensable aux séquences qui ne sont pas partagées
entre les _shards_.

Dans un cas réel, on imaginerait une transformation de type _hash_ sur un
identifiant civile, tel que le numéro de sécurité sociale. Cet identifiant permet
de préserver la correspondance avec l'individu réel pour mettre à jour ses
informations, telle que la date du décés.

* Cloner la base `region_template` pour les dix-huits régions administratives.
  Dans la pratique, il s'agira de dix-huit bases de données ayant leurs propres 
  ressources serveurs (CPU, mémoire et stockage) sur des instances dédiées.

```sql
SELECT concat(
  'CREATE DATABASE region_', replace(lower(region_id), '-', ''),
  ' WITH TEMPLATE = region_template;'
) FROM regions;
\gexec
```

### Configurer les accès distants

* Créer la base principale `recensement` à partir du _template_ précédent.

```sql
CREATE DATABASE recensement WITH TEMPLATE = region_template;
```

* Dans cette nouvelle base, installer l'extension `postgres_fdw`, et créer les
  serveurs distants pour chaque base de région, ainsi que les correspondances
  d'utilisateur nécessaires à l'authentification des tables distantes.

```sql
\c recensement

CREATE EXTENSION postgres_fdw;
SELECT concat(
  'CREATE SERVER IF NOT EXISTS server_', replace(lower(region_id), '-', ''),
  ' FOREIGN DATA WRAPPER postgres_fdw OPTIONS (',
  '  host ''/tmp'', port ''' || current_setting('port') || ''','
  '  dbname ''region_', replace(lower(region_id), '-', ''), ''',',
  '  async_capable ''on''',
  ' );'
) FROM regions;
\gexec

SELECT concat(
  'CREATE USER MAPPING IF NOT EXISTS FOR current_user SERVER server_',
    replace(lower(region_id), '-', ''), ';'
) FROM regions;
\gexec
```

L'option `async_capable` doit être activée pour bénéficier de la lecture 
concurrente sur les partitions distantes.

* Dans la base principale `recensement`, recréer la table `population` en 
  table partitionnée de type `LIST` sur la colonne `region_naissance_id`.

```sql
DROP TABLE IF EXISTS population;
CREATE TABLE population (
  anon_id uuid DEFAULT gen_random_uuid(),
  region_naissance_id varchar(6) NOT NULL,
  date_naissance date NOT NULL,
  date_deces date
) PARTITION BY LIST (region_naissance_id);
```

PostgreSQL ne supporte pas (encore) les contraintes de clés primaires et de clés
étrangères pour des partitions distantes. C'est pour cette raison que la table
partitionnée n'en fait pas mention. Le contournement consiste à les définir
scrupuleusement sur les serveurs distants et de reposer sur un identifiant
universellement unique comme le type `uuid` pour régler les risques de conflits.

* Pour chaque base région, créer une partition distante rattachée à la table
  principale `population`.

```sql
SELECT concat(
  'CREATE FOREIGN TABLE population_', replace(lower(region_id), '-', ''),
  '  PARTITION OF population FOR VALUES IN (''',region_id,''')',
  '  SERVER server_', replace(lower(region_id), '-', ''),
  '  OPTIONS (table_name ''population'');'
) FROM regions;
\gexec
```

### Alimenter une table partitionnée répartie dans plusieurs bases de données

* Insérer des données aléatoires dans la table principale.

```sql
\timing on
EXPLAIN (verbose, costs off)
INSERT INTO population (region_naissance_id, date_naissance) 
SELECT region_id, d FROM regions
 CROSS JOIN generate_series(1, 1000) i
 CROSS JOIN generate_series('1970-01-01', '2010-01-01', '1 year'::interval) d;
```
```text
INSERT 0 738000
Time: 52580,749 ms (00:52,581)
```

L'insertion est pénalisée par la distribution des lignes à travers les différentes
tables distantes, les contraintes d'intégrité qui s'appliquent, la mise à jour
des index de clé primaire, voire l'appel à la fonction `gen_random_uuid()`.

* Exécuter la commande `ANALYZE` sur la table principale.

```sql
ANALYZE VERBOSE population;
```

### Étudier les différents cas d'usage

* Afficher le plan d'exécution d'une requête permettant de comptabiliser le
  nombre de naissance en 2010.

```sql
EXPLAIN (analyze, costs off) 
 SELECT count(anon_id) FROM population 
  WHERE date_naissance BETWEEN '2010-01-01' AND '2011-01-01';
```
```text
                                QUERY PLAN
--------------------------------------------------------------------------------
 Aggregate (actual time=50.682..50.686 rows=1 loops=1)
   ->  Append (actual time=32.577..49.675 rows=18000 loops=1)
         ->  Async Foreign Scan on population_frara population_1
               (actual time=0.709..1.845 rows=1000 loops=1)
         ->  Async Foreign Scan on population_frbfc population_2
               (actual time=0.883..1.721 rows=1000 loops=1)
 ...
         ->  Async Foreign Scan on population_frpac population_17
               (actual time=0.404..1.096 rows=1000 loops=1)
         ->  Async Foreign Scan on population_frpdl population_18
               (actual time=0.262..0.942 rows=1000 loops=1)
 Planning Time: 1.608 ms
 Execution Time: 56.747 ms
```

On constate que les nœuds `Async Foreign Scan` démarrent presque au même instant
(`actual time=0..`) et que le nœud `Append`, chargé de l'union des résultat, se 
termine vers la 49ème milliseconde d'exécution. Sur de hautes volumétries, les 
lectures non indexées sont plus performantes, grâce à une répartition de travail 
entre les différentes instances, aussi appelées nœuds de calcul.

* Réexécuter la requête en désactivant l'option `async_capable` sur les partitions.

```sql
SELECT concat(
  'ALTER FOREIGN TABLE ', ftrelid::regclass, 
  '  OPTIONS (ADD async_capable ''off'');'
) FROM pg_foreign_table;
\gexec

EXPLAIN (analyze, costs off) 
 SELECT count(anon_id) FROM population 
  WHERE date_naissance BETWEEN '2010-01-01' AND '2011-01-01';
```
```text
                                QUERY PLAN
--------------------------------------------------------------------------------
 Aggregate (actual time=194.068..194.082 rows=1 loops=1)
   ->  Append (actual time=10.472..191.945 rows=18000 loops=1)
         ->  Foreign Scan on population_frara population_1 
               (actual time=10.470..17.210 rows=1000 loops=1)
         ->  Foreign Scan on population_frbfc population_2 
               (actual time=10.757..18.176 rows=1000 loops=1)
 ...
         ->  Foreign Scan on population_frpac population_17 
               (actual time=7.390..12.589 rows=1000 loops=1)
         ->  Foreign Scan on population_frpdl population_18 
               (actual time=8.227..13.544 rows=1000 loops=1)
 Planning Time: 1.217 ms
 Execution Time: 203.204 ms
```

Cette fois-ci, on constate un retard dans le démarrage des lectures et que le
nœud `Append` ne termine l'union des 18 résultats qu'après 191 milliseconde.

Pour réactiver les options, exécuter la requête suivante :

```sql
SELECT concat(
  'ALTER FOREIGN TABLE ', ftrelid::regclass, 
  '  OPTIONS (DROP async_capable);'
) FROM pg_foreign_table;
\gexec
```

* Procéder à la mise à jour de la table `population` pour ajouter une date de 
  décès à une portion de la population. Récupérer le nombre de décès survenus
  entre 1970 et 1980, regroupés par région.

```sql
EXPLAIN (analyze, verbose, costs off)
UPDATE population 
   SET date_deces = date_naissance + trunc(random() * 70)::int
 WHERE anon_id::text like 'ff%'
   AND date_naissance < '1980-01-01';
```
```text
                                QUERY PLAN
--------------------------------------------------------------------------------
 Update on population (actual time=979.144..979.152 rows=0 loops=1)
  Foreign Update on public.population_frara population_1
   Remote SQL: UPDATE public.population SET date_deces = $2 WHERE ctid = $1
  ...
  Foreign Update on public.population_frpdl population_18
   Remote SQL: UPDATE public.population SET date_deces = $2 WHERE ctid = $1
   -> Append (actual time=137.350..1200.934 rows=701 loops=1)
      -> Foreign Scan on public.population_frara population_1 
          (actual time=137.347..138.112 rows=37 loops=1)
           Filter: ((population_1.anon_id)::text ~~ 'ff%'::text)
           Rows Removed by Filter: 9963
           Remote SQL: 
            SELECT anon_id, region_naissance_id, date_naissance, date_deces, ctid 
              FROM public.population WHERE ((date_naissance < '1980-01-01'::date))
               FOR UPDATE
 ...
      -> Foreign Scan on public.population_frpdl population_18 
          (actual time=38.566..38.676 rows=39 loops=1)
           Filter: ((population_18.anon_id)::text ~~ 'ff%'::text)
           Rows Removed by Filter: 9961
           Remote SQL: 
            SELECT anon_id, region_naissance_id, date_naissance, date_deces, ctid 
              FROM public.population WHERE ((date_naissance < '1980-01-01'::date)) 
               FOR UPDATE
 Planning Time: 2.370 ms
 Execution Time: 1312.767 ms
```

Lors d'une mise à jour des lignes, le `foreign data wrapper` implémente une prise
de verrou `FOR UPDATE` avant la modification, comme le montre le plan d'exécution
avec l'option `VERBOSE`. Cependant, cette étape ne parcourt pas les tables en 
asychrone bien que l'option soit activée. Le temps cumulé pour ces verrous 
représente une grande partie de l'exécution de la requête `UPDATE`, soit environ 
1200 milliseconde sur les 1312 au total.

Pour une architecture distribuée minimale, les lectures sont grandement améliorées
avec la nouvelle option `async_capable` sur des tables partitionnées. Pour les
modifications, il convient de favoriser l'usage de la clé primaire distante pour
garantir des temps de réponse optimum.
</div>
