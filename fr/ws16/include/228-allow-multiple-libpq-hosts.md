<!--
Les sources pour ce sujet sont :

* https://git.postgresql.org/gitweb/?p=postgresql.git;a=commit;h=7f5b19817eaf38e70ad1153db4e644ee9456853e

Discussion :

* https://www.postgresql.org/message-id/flat/PR3PR83MB04768E2FF04818EEB2179949F7A69@PR3PR83MB0476.EURPRD83.prod.outlook.com

-->

<div class="slide-content">

  * Répartiton de la charge de connexions entre plusieurs instances
  * Nouveau paramètre `libpq`
    + `load_balance_hosts=<string>`

</div>

<div class="notes">

Un nouveau paramètre de connexion voit le jour au niveau de `libpq`. Il permet
de faire de la répartition de charge au niveau des connexions à plusieurs
instances PostgreSQL. Le paramètre `load_balance_hosts=<string>` peut prendre
plusieurs valeurs : 

* `disable` (valeur par défaut)
* `random`

Dans le premier cas, les tentatives de connexions se font de manière
séquentielle, les adresses sont testées dans l'ordre. Si des noms DNS sont
indiqués, ils seront résolus puis les connexions se feront selon l'ordre de la
ou les adresses IP obtenues par la résolution DNS.

Lorsque `random` est utilisé, l'ordre de prise en compte est aléatoire. Si
une résolution DNS est nécessaire, l'ordre des adresses IP obtenues sera lui
aussi mélangé pour ne pas toujours se connecter à la même adresse IP pour un nom
de domaine donné.

Il est à noter que cette répartition de charge se fait au niveau des connexions
et non pas au niveau des transactions. Cela signifie qu'un contrôle est tout de
même nécessaire sur les transactions qui sont effectuées après la connexion.

Par exemple, dans le cas suivant, nous avons trois instances PostgreSQL dont
deux qui se trouvent être des secondaires en lecture seule. Il est donc possible
d'effectuer des `SELECT` sur toutes les instances. Dans cet exemple, le `SELECT`
renvoie l'adresse IP de l'instance, mais il est facile d'étendre cet exemple à
des requêtes plus fonctionnelles.

```sh
$ cat /etc/hosts
...
10.0.3.114  pg16_1
10.0.3.19   pg16_2
10.0.3.97   pg16_3

$ for i in {1..10}; do PGPASSWORD=dalibo psql -At 'user=dalibo dbname=dalibo host=pg16_1,pg16_2,pg16_3 load_balance_hosts=random' -c "select inet_server_addr();" ; done
10.0.3.97
10.0.3.114
10.0.3.114
10.0.3.19
10.0.3.19
10.0.3.114
10.0.3.97
10.0.3.114
10.0.3.19
10.0.3.97
```

Toutes les instances ont répondues correctement.

Maintenant, si la requête passée est un `INSERT` sur la base `dalibo`, des
messages d'erreurs apparaissent lors de l'exécution sur les secondaires. Ceci
est logique puisque ces instances là sont en lecture seule. Par exemple :

```sh
$ for i in {1..10}; do PGPASSWORD=dalibo psql -At 'user=dalibo dbname=dalibo host=pg16_1,pg16_2,pg16_3 load_balance_hosts=random' -c "select inet_server_addr(); insert into test_random values ('1');" ; done

10.0.3.19 # secondaire
ERROR:  cannot execute INSERT in a read-only transaction
10.0.3.97 # secondaire
ERROR:  cannot execute INSERT in a read-only transaction
10.0.3.114 # <-- primaire
INSERT 0 1
10.0.3.19 # secondaire
ERROR:  cannot execute INSERT in a read-only transaction
10.0.3.97 # secondaire
ERROR:  cannot execute INSERT in a read-only transaction
10.0.3.19 # secondaire
ERROR:  cannot execute INSERT in a read-only transaction
10.0.3.114 # <-- primaire
INSERT 0 1
10.0.3.19 # secondaire
ERROR:  cannot execute INSERT in a read-only transaction
10.0.3.114 # <-- primaire
INSERT 0 1
10.0.3.19 # secondaire
ERROR:  cannot execute INSERT in a read-only transaction
```

Rappelons au passage que l'option `target_session_attrs` permet de spécifier à
quel type d'instance le client peut se connecter. Par exemple
`target_session_attrs=primary` permet au client de se connecter uniquement
sur des instances primaires. Le test précédent ne remonte plus d'erreur.

```sh
$ for i in {1..10}; do PGPASSWORD=dalibo psql -At 'user=dalibo dbname=dalibo host=pg16_1,pg16_2,pg16_3 load_balance_hosts=random target_session_attrs=primary' -c "select inet_server_addr(); insert into test_random values ('1');" ; done

10.0.3.114 # <-- primaire
INSERT 0 1
10.0.3.114 # <-- primaire
INSERT 0 1
...
```

Cette nouvelle option permet de manière très simple d'effectuer de la
répartition de charge sur plusieurs secondaires de manière équilibrée ou
pondérée. Attirons néanmoins l'attention sur le fait que la répartition se fait
au niveau des requêtes, et non pas au niveau de la charge réelle.

Reprenons l'exemple avec cette fois-ici uniquement nos deux serveurs
secondaires. Pour avoir une répartition équilibrée, rien de plus simple, il
suffit d'indiquer les deux serveurs. On peut facilement estimer la répartition
entre les deux instances avec une combinaison de commandes `grep 97` (97 faisant
parti de l'adresse IP de pg16_3) et `wc`.

```sh
$ for i in {1..10}; do PGPASSWORD=dalibo psql -At 'user=dalibo dbname=dalibo host=pg16_2,pg16_3 load_balance_hosts=random' -c "select inet_server_addr(); " ; done | grep 97 | wc
```

En modifiant le nombre de passages dans la boucle, on obtient le tableau
suivant, montrant une répartition équilibrée des requêtes :

| itérations | 10 | 100 | 1000 | 10000 |
|------------|----|-----|------|-------|
| pg16_2     | 6  | 46  | 489  | 5009  |
| pg16_3     | 4  | 54  | 511  | 4991  |

Si désormais, on veut favoriser l'utilisation du secondaire `pg16_3`, il suffit
de le rajouter une seconde fois dans la ligne de commande, afin d'obtenir, par exemple un
ratio 1/3 - 2/3 en terme d'utilisation des secondaires `pg16_2` et `pg16_3`.

```sh
$ for i in {1..10}; do PGPASSWORD=dalibo psql -At 'user=dalibo dbname=dalibo host=pg16_2,pg16_3,pg16_3 load_balance_hosts=random' -c "select inet_server_addr();" ; done | grep 97 | wc
```

| itérations | 10 | 100 | 1000 | 10000 |
|------------|----|-----|------|-------|
| pg16_2     | 3  | 34  |  332 |  3322 |
| pg16_3     | 7  | 66  |  668 |  6678 |

De manière très simple, il est désormais possible de faire de la répartion de
charge en lecture sur plusieurs secondaires avec `libpq`.

</div>
