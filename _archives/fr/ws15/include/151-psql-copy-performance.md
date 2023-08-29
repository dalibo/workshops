<!--
Les commits sur ce sujet sont :

* https://commitfest.postgresql.org/33/2973/

Discussion

* https://www.postgresql.org/message-id/flat/40b2cec0-d0fb-3191-2ae1-9a3fe16a7e48@iki.fi

-->


<div class="slide-content">

 * optimisation de la méta-commande psql `\copy from`

</div>

<div class="notes">


L'utilisation de plus larges segments de données par la commande psql 
`\copy from` permet d'effectuer plus rapidement l'import de données dans des 
tables.

Le gain observé approche les 10% sur un fichier de données contenant 20 millions 
d'entrées.

PostgreSQL 14 :

```sql
postgres=# \copy t1 from '~/data.txt';
COPY 20000000
Time: 9755.384 ms (00:09.755)
```

PostgreSQL 15 :

```sql
postgres=# \copy t1 from '~/data.txt';
COPY 20000000
Time: 8920.834 ms (00:08.921)
postgres=#
```

Si ce transfert passe par une connexion distante, la quantité de trafic réseau 
est également réduite.

</div>