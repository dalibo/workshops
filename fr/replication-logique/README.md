# Pré-requis

Avant d'arriver au workshop, les participants devront avoir préparé leurs
postes de travail afin de disposer de:

* VirtualBox

Ils recevront alors une VM CentOS 7, installée comme suit.

## Installation de PostgreSQL 10

```
# yum install https://download.postgresql.org/pub/repos/yum/10/redhat/rhel-7-x86_64/pgdg-centos10-10-2.noarch.rpm
# yum install postgresql10-server
# /usr/pgsql-10/bin/postgresql-10-setup initdb
# systemctl start postgresql-10
```

Cette instance servira de serveur origine de la réplication logique et sera appelée s1.

## Initialisation d'une base de test "b1" contenant les tables "t1" et "t2"

```
# sudo -iu postgres createdb b1
# sudo -iu postgres psql b1
b1=# CREATE TABLE t1 (id_t1 serial, label_t1 text);
	 CREATE TABLE t2 (id_t2 serial, label_t2 text);
	 INSERT INTO t1 SELECT i, 't1, ligne '||i FROM generate_series(1, 100) i;
	 INSERT INTO t2 SELECT i, 't2, ligne '||i FROM generate_series(1, 1000) i;
	 ALTER TABLE t1 ADD PRIMARY KEY(id_t1);
	 ALTER TABLE t2 ADD PRIMARY KEY(id_t2);
```

## Installation de PostgreSQL 11, sur le port 5433

```
# yum install https://download.postgresql.org/pub/repos/yum/11/redhat/rhel-7-x86_64/pgdg-centos11-11-2.noarch.rpm
# yum install postgresql11-server
# /usr/pgsql-11/bin/postgresql-11-setup initdb
# echo "port = 5433" >> /var/lib/pgsql/11/data/postgresql.conf
# systemctl start postgresql-11
```

Cette instance servira de serveur destination de la réplication logique et sera appelée s2.