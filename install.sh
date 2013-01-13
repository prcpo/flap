#!/bin/bash

# Имя создаваемой базы данных
DATABASE=test

# IP адрес или имя сервера.
HOST=localhost

# Имя пользователя, обладающего правами создавать и удалять базы данных (адинистратора баз данных)
DBA=postgres
# и его пароль
DBAPASSWD=postgres

# Имя создаваемого пользователя, который будет администратором создаваемой базы данных
ADMIN=admin
# и его пароль
ADMINPASSWD=admin


TMP_PATH=/tmp
CUR_PATH=$PWD

SQL='psql -h '$HOST' -U '$ADMIN' -1 -d '$DATABASE' -f'
SQLDBA='psql -h '$HOST' -U '$DBA

cd sql


cat database_drop.sql.template | sed 's/__DATABASE__/'$DATABASE'/g'  > $TMP_PATH/database_drop.sql
cat database_create.sql.template | sed 's/__DATABASE__/'$DATABASE'/g'  > $TMP_PATH/database_create.sql

# Создание базы данных от имени DBA
PGPASSWORD=$DBAPASSWD
export PGPASSWORD

echo drop old database...
$SQLDBA -f $TMP_PATH/database_drop.sql;
echo create database...
$SQLDBA -f $TMP_PATH/database_create.sql;

echo create admin...
$SQLDBA -c "CREATE USER "$ADMIN" WITH CREATEROLE REPLICATION PASSWORD '"$ADMINPASSWD"'" ;
echo set owner...
$SQLDBA -c 'ALTER DATABASE '$DATABASE' OWNER TO '$ADMIN ;
echo grant...
$SQLDBA -c 'GRANT ALL PRIVILEGES ON DATABASE '$DATABASE' to '$ADMIN ;

# А вот схему ext в БД надо создавать от имени нашего админитратора
PGPASSWORD=$ADMINPASSWD
export PGPASSWORD

echo ext...
$SQL ext.sql;

# Чтобы добавить расширения в схему ext опять нужны права DBA
PGPASSWORD=$DBAPASSWD
export PGPASSWORD;

echo extensions...
$SQLDBA -d $DATABASE -f extentions.sql;

# Всё остальное делаем от имени нашего администратора
PGPASSWORD=$ADMINPASSWD
export PGPASSWORD;

echo roles...
$SQL roles.sql;
echo json...
$SQL json.sql;
echo def...
$SQL def.sql;
echo tools...
$SQL tools.sql;
echo test...
$SQL test.sql;
echo sec...
$SQL sec.sql;
echo set...
$SQL set.sql;
echo obj...
$SQL obj.sql;

echo public...
$SQL public.sql;

PGPASSWORD=
export PGPASSWORD;

cd $CUR_PATH;
