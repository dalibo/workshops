<!--
Les commits sur ce sujet sont :

* https://git.postgresql.org/gitweb/?p=postgresql.git;a=commit;h=a563c24c9574b74f4883c004c89275bba03c3c26

Discussions :

* https://postgr.es/m/5aa393b5-5f67-8447-b83e-544516990ee2@migops.com

-->

<div class="slide-content">

  * Trois nouvelles options sont disponibles pour `pg_dump`
    + `--table-and-children`
    + `--exclude-table-and-children`
    + `--exclude-table-data-and-children`
  * Inclusion ou exclusion de partitions lors d'une sauvegarde d'une table partitionnée

</div>

<div class="notes">

L'outil `pg_dump` permet désormais d'inclure ou d'exclure les tables enfants et
les partitions de la sauvegarde logique. Pour cela, trois options ont été
ajoutées : 

* `--table-and-children` : permet de sauvegarder seulement les tables dont le
  nom correspond au motif ainsi que leurs tables enfants ou partitions qui
  existeraient.
* `--exclude-table-and-children` : permet d'exclure les tables dont le nom
  correspond au motif ainsi que leurs tables enfants ou partitions qui
  existeraient.
* `--exclude-table-data-and-children` : permet d'exclure les données des tables
  dont le nom correspond au motif ainsi que celles de leurs tables enfants ou
  partitions qui existeraient.

Les options `--exclude-table-data-and-children` et
`--exclude-table-and-children` peuvent être appelées plusieurs fois dans la
commande.

Imaginons une base de données `cave` d'un professionnel avec toutes ses références de
bouteilles de vin, de cavistes, de récoltants. Imaginons ensuite la table `stock` qui contient
les bouteilles disponibles. La table `stock` est partitionnée selon l'année de
la bouteille. Particularité pour les bouteilles de 2001, elles sont également
triées selon leur cru (1, 2 ou 3).

Dans un premier temps, voyons ce que l'option `--table-and-children` permet de faire.
Pour sauvegarder le stock tout entier, il est possible d'utiliser cette nouvelle
option. `pg_restore --list` nous confirme bien que les tables enfants ont été
prises en compte.

```sh
# Sauvegarde
$ pg_dump -d cave -U postgres -Fc --table-and-children=stock* > stock.pgdump

# Inspection
$ pg_restore --list stock.pgdump 
;
; Archive created at 2023-11-10 09:47:10 CET
;     dbname: cave
;     TOC Entries: 32
[...]

# Les définitions des tables sont bien sauvegardées ...
228; 1259 41285 TABLE public stock postgres
233; 1259 41311 TABLE public stock_2001 postgres
234; 1259 41314 TABLE public stock_2001_1 postgres
236; 1259 41320 TABLE public stock_2001_2 postgres
235; 1259 41317 TABLE public stock_2001_3 postgres
229; 1259 41291 TABLE public stock_2002 postgres
230; 1259 41294 TABLE public stock_2003 postgres
231; 1259 41297 TABLE public stock_2004 postgres
232; 1259 41300 TABLE public stock_2005 postgres

# ... ainsi que leurs données
3440; 0 41314 TABLE DATA public stock_2001_1 postgres
3442; 0 41320 TABLE DATA public stock_2001_2 postgres
3441; 0 41317 TABLE DATA public stock_2001_3 postgres
3436; 0 41291 TABLE DATA public stock_2002 postgres
3437; 0 41294 TABLE DATA public stock_2003 postgres
3438; 0 41297 TABLE DATA public stock_2004 postgres
3439; 0 41300 TABLE DATA public stock_2005 postgres
[...]
```

Prenons le cas maintenant d'un très bon acheteur qui demanderait un export de toutes
les bouteilles du stock sauf celle de l'année 2001. Il souhaite intégrer
ces données dans sa propre base.

L'option `--exclude-table-and-children` de `pg_dump` peut être utilisée pour
satisfaire sa demande. Cette option permet d'exclure les données de la table
stock_2001 ainsi que ses partitions. L'option `-T` de `pg_dump` n'aurait pas
permis cela.

```sh
# Sauvegarde
$ pg_dump -d cave -U postgres -Fc --table-and-children=stock* --exclude-table-and-children=stock_2001 > stock_pour_client.pgdump

# Inspection
$ pg_restore --list stock_meilleures_annees.pgdump 

[...]
228; 1259 41285 TABLE public stock postgres
229; 1259 41291 TABLE public stock_2002 postgres
230; 1259 41294 TABLE public stock_2003 postgres
231; 1259 41297 TABLE public stock_2004 postgres
232; 1259 41300 TABLE public stock_2005 postgres
[...]
3433; 0 41291 TABLE DATA public stock_2002 postgres
3434; 0 41294 TABLE DATA public stock_2003 postgres
3435; 0 41297 TABLE DATA public stock_2004 postgres
3436; 0 41300 TABLE DATA public stock_2005 postgres
[...]
```

À noter que l'option `--table-and-children=stock` est encore nécessaire, sans
quoi, toute la base de données serait exportée.

Voici le résultat que nous aurions obtenu avec l'option `-T`. Toutes les
partitions de stock_2001 auraient été sauvegardées.

```sh
# Sauvegarde
$ pg_dump -d cave -U postgres -Fc --table-and-children=stock* -T stock_2001 > stock_pour_client.pgdump

# Inspection
$ pg_restore --list stock_meilleures_annees.pgdump 

[...]
228; 1259 41285 TABLE public stock postgres
234; 1259 41314 TABLE public stock_2001_1 postgres  <-- la définition est gardée
236; 1259 41320 TABLE public stock_2001_2 postgres  <-- la définition est gardée
235; 1259 41317 TABLE public stock_2001_3 postgres  <-- la définition est gardée
229; 1259 41291 TABLE public stock_2002 postgres
230; 1259 41294 TABLE public stock_2003 postgres
231; 1259 41297 TABLE public stock_2004 postgres
232; 1259 41300 TABLE public stock_2005 postgres
[...]
3440; 0 41314 TABLE DATA public stock_2001_1 postgres  <-- les données sont conservées
3442; 0 41320 TABLE DATA public stock_2001_2 postgres  <-- les données sont conservées
3441; 0 41317 TABLE DATA public stock_2001_3 postgres  <-- les données sont conservées
3436; 0 41291 TABLE DATA public stock_2002 postgres
3437; 0 41294 TABLE DATA public stock_2003 postgres
3438; 0 41297 TABLE DATA public stock_2004 postgres
3439; 0 41300 TABLE DATA public stock_2005 postgres
[...]
```

Enfin la dernière option `--exclude-table-data-and-children` permet de ne pas
sauvegarder le contenu de la table et de ses partitions, mais uniquement la
définition. Par exemple, si notre caviste s'est rendu compte d'une erreur sur
toute l'année 2001 qui doit entièrement être reprise, une commande de sauvegarde
pourrait être :

```sh
# Sauvegarde
$ pg_dump -d cave -U postgres -Fc --table-and-children=stock* --exclude-table-data-and-children=stock_2001 > stock_reset_2001.pgdump

# Inspection
$ pg_restore --list stock_reset_2005.pgdump

[...]
228; 1259 41285 TABLE public stock postgres
233; 1259 41311 TABLE public stock_2001 postgres    <-- la définition est gardée
234; 1259 41314 TABLE public stock_2001_1 postgres  <-- la définition est gardée
236; 1259 41320 TABLE public stock_2001_2 postgres  <-- la définition est gardée
235; 1259 41317 TABLE public stock_2001_3 postgres  <-- la définition est gardée
229; 1259 41291 TABLE public stock_2002 postgres
230; 1259 41294 TABLE public stock_2003 postgres
231; 1259 41297 TABLE public stock_2004 postgres
232; 1259 41300 TABLE public stock_2005 postgres
[...]
3436; 0 41291 TABLE DATA public stock_2002 postgres  <-- les données conservées débutent en 2002
3437; 0 41294 TABLE DATA public stock_2003 postgres
3438; 0 41297 TABLE DATA public stock_2004 postgres
3439; 0 41300 TABLE DATA public stock_2005 postgres
```

</div>
