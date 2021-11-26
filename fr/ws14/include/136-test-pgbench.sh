#!/bin/bash

export PGDATABASE=bench
echo "Config : $PGDATABASE $PGPORT $PGHOST $PGUSER"

if [ -z "$PGDATABASE" -o -z "$PGPORT" -o -z "$PGHOST" -o -z "$PGUSER" ] ; then
    echo "renseigner l environnement la config!"
    exit 1
fi

dropdb --echo --force --if-exists $PGDATABASE

P="psql -X --pset pager=off -d $PGDATABASE "

set -xue
createdb --echo $PGDATABASE
pgbench -i -s 100 --unlogged-tables
$P -c 'CREATE INDEX ON pgbench_accounts (abalance) '
$P -c '\d+' -c '\di+'
$P -c 'ALTER TABLE pgbench_accounts SET (autovacuum_enabled = off)'
$P -c 'ALTER TABLE pgbench_history SET (autovacuum_enabled = off)'
pgbench -n -c 50 -t30000 -r -P10
$P -c '\d+'
$P -c '\di+'

echo "Rappel config : $PGDATABASE $PGPORT $PGHOST $PGUSER"

