<!--                                                                                                                                                                                          
Les commits sur ce sujet sont :                                                                                                                                                               

* https://git.postgresql.org/gitweb/?p=postgresql.git;a=commit;h=a2c84990bea7beadb599d02328190e2a763dcb86
                                                                                                                                                                                            
Discussion                                                                                                                                                                                    

* https://gitlab.dalibo.info/formation/workshops/-/issues/159                                                                                                                                                                                              
-->

<div class="slide-content">                                                                                                                                                                   

* Nouvelle vue `pg_ident_file_mappings`
* Résume le contenu actuel du fichier `pg_ident.conf`
* Permet le diagnostique d'erreur et la validation de la configuration

</div>

<div class="notes">

De façon similaire à la vue `pg_hba_file_rules`, la nouvelle vue système `pg_ident_file_mappings` donne 
un résumé du fichier de configuration `pg_ident.conf`. En plus des informations contenues dans le fichier 
`pg_ident.conf`, elle fournit une colonne `error` qui va permettre de vérifier le fonctionnement de la 
configuration avant application ou de diagnostiquer un éventuel problème.

Cette vue n'intervient que sur le contenu actuel du fichier, et non pas sur ce qui a pu être chargé par 
le serveur. Par défaut elle n'est accessible que pour les super-utilisateurs.

Voici un exemple de ce que peut retourner la vue `pg_ident_file_mappings` :

```sql
postgres=# select * from pg_ident_file_mappings;
 line_number | map_name |         sys_name         | pg_username |            error             
-------------+----------+--------------------------+-------------+------------------------------
          43 | workshop | dalibo                   | test        | 
          44 | mymap    | /^(.*)@mydomain\.com$    | \1          | 
          45 | mymap    | /^(.*)@otherdomain\.com$ | guest       | 
          46 |          |                          |             | missing entry at end of line
```

On peut remarquer ci-dessus, qu'une erreur est retournée par la vue `pg_ident_file_mappings` à la 
ligne 46 du fichier `pg_ident.conf` : `missing entry at end of line`. 

</div>
