<!--
Les commits sur ce sujet sont :

* civles: https://www.postgresql.org/message-id/E1nAZj6-0005S2-7T@gemulon.postgresql.org
* pg_file_settings: https://www.postgresql.org/message-id/E1nDV7S-0003Tr-1d@gemulon.postgresql.org
* backup_to_shell: https://www.postgresql.org/message-id/E1nUB2m-000CYD-DY@gemulon.postgresql.org

Discussion dans les commits

-->

<div class="slide-content">

  * Nouveau paramètre `-t/--target` pour `pg_basebackup`
    + `client`, `server` ou `blackhole`
  * Sauvegarde sur le serveur seulement accessible aux membres 
  du groupe `pg_write_server_files`
  * Possibilité d'ajouter des cibles via des modules additionnels
    + module `basebackup_to_shell` fourni en exemple

</div>

<div class="notes">

Cette version introduit la notion de cible pour les sauvegardes effectuées avec
`pg_basebackup`. Le nouveau paramètre `-t/--target` a été introduit à cet
effet. Il peut prendre les valeurs :

* `client` : la sauvegarde est faite en local (c'est la valeur par défaut) ;
* `server` : la sauvegarde est faite sur le serveur de base de données ;
* `blackhole` : aucun fichier n'est créé, c'est utile pour les tests ;

Pour les modes `client` et `server`, il faut spécifier un chemin :

* pour `client`, il faut utiliser l'option `-D/--pgdata` ;
* pour `server`, il faut affixer  `:` suivit d'un chemin à la cible.

Sauvegarder sur le serveur de base de données est une tâche plus sensible
qu'effectuer une sauvegarde en local. C'est pour cette raison qu'il faut faire
partie du groupe `pg_write_server_files` pour pouvoir utiliser cette cible.

Lorsque la cible est différente de `client`, l'option `-X/--wal-method` est
requise et doit prendre la valeur `none` ou `fetch`. Si l'on choisit la méthode
`fetch`, il peut donc être nécessaire de configurer `wal_keep_size` pour
s'assurer que les WAL nécessaires pour rendre la sauvegarde cohérente soient
conservés jusqu'à la fin de l'opération. Si l'archivage est déjà configuré,
l'option `none` peut être utilisée.

Voici quelques exemples de syntaxe pour la commande :

```bash
# Sauvegarde sur le serveur du client
pg_basebackup --checkpoint fast --progress \
              --target client --pgdata .

# Sauvegarde "à blanc"
pg_basebackup --checkpoint fast --progress \
              --target blackhole --wal-method fetch

# Sauvegarde sur le serveur de base de données
pg_basebackup --checkpoint fast --progress \
              --target server:/backup/15/main --wal-method fetch
```

Pour toutes les cibles différentes de `client` (la valeur par défaut), le
format de la sauvegarde est obligatoirement `tar`. Par exemple, si `--format p`
et `--target=server` sont spécifiés, l'erreur suivante est affichée.

```text
pg_basebackup: error: cannot specify both format and backup target
```

Il est prévu de pouvoir étendre le fonctionnement de `pg_basebackup` en ajoutant
de nouveaux types de cibles. Le module de test `basebackup_to_shell` est fourni
à titre d'exemple. Il permet d'exécuter une commande qui prend en entrée
standard un fichier généré par la sauvegarde.

Le module ajoute à `pg_basebackup` la cible `shell`, pour laquelle il est
possible d'affixer `:` et une chaîne de caractère. Cette chaîne de caractère ne
peut contenir que des caractères alphanumériques.

Pour l'utiliser, il faut ajouter le module à `shared_preload_libraries` ou
`local_preload_libraries`, et configurer les paramètres :

* `basebackup_to_shell.command` : une commande que le serveur va utiliser pour
  chaque fichier généré par `pg_basebackup`. Si `%f` est spécifié dans la
  commande, il sera remplacé par le nom de fichier. Si `%d` est spécifié dans
  la commande, il sera remplacé par la chaîne spécifiée après la cible ;

* `basebackup_to_shell.required_role` : le rôle requis pour pouvoir utiliser la
  cible `shell`. Il faut que l'utilisateur dispose de l'attribut `REPLICATION`.

Le module est fourni à titre d'exemple pour démontrer la création de ce genre
de module et son utilisation. Son utilité est limitée. Nous allons ici
l'utiliser pour chiffrer la sauvegarde :

```bash
BACKUP=$HOME/backup
PGDATA=$HOME/data
PGPORT=5656
PGUSER=$USER

mkdir -p $PGDATA $BACKUP

initdb --data-checksum $PGDATA

cat << __EOF__ >> $PGDATA/postgresql.conf
port = $PGPORT
listen_addresses = '*'
cluster_name = 'test_shell_module'
shared_preload_libraries = 'basebackup_to_shell'
basebackup_to_shell.command = 'gpg --encrypt --recipient %d --output $BACKUP/%f'
basebackup_to_shell.required_role = 'gpg'
__EOF__

pg_ctl start -D $PGDATA

psql -c "CREATE ROLE gpg WITH LOGIN PASSWORD 'secret'"
psql -c "CREATE ROLE non_autorise WITH LOGIN PASSWORD 'secret'"
echo "localhost:5656:postgres:gpg:secret" >> $HOME/.pgpass
echo "localhost:5656:postgres:non_autorise:secret" >> $HOME/.pgpass
chown $USER $HOME/.pgpass
chmod 600 $HOME/.pgpass
```

Effectuer une sauvegarde avec le module `shell` et l'utilisateur **gpg** :

```bash
pg_basebackup --checkpoint fast --progress --user gpg \
              --target shell:$PGUSER --wal-method fetch
```

On peut contrôler que le `backup_manifest` est bien chiffré en l'éditant.
Pour l'afficher en clair :

```bash
gpg -d $BACKUP/backup_manifest
```

Avec l'utilisateur **non_autorise**, la sauvegarde échoue :

```bash
pg_basebackup --checkpoint fast --progress --user non_autorise \
              --target shell:$PGUSER --wal-method fetch
```
```sh
pg_basebackup: error: could not initiate base backup:
+++ ERROR:  permission denied to use basebackup_to_shell
```

</div>
