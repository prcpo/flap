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

$SQLDBA -f $TMP_PATH/database_drop.sql
$SQLDBA -f $TMP_PATH/database_create.sql;

# Создание базы данных от имени DBA
PGPASSWORD=$DBAPASSWD
export PGPASSWORD

$SQLDBA -c "CREATE USER "$ADMIN" WITH PASSWORD '"$ADMINPASSWD"'"
$SQLDBA -c 'GRANT ALL PRIVILEGES ON DATABASE '$DATABASE' to '$ADMIN

# А вот схему ext в БД нао создавать от имени нашего админитратора
PGPASSWORD=$ADMINPASSWD
export PGPASSWORD

$SQL ext.sql;

# Чтобы добавить расширения в схему ext опять нужны права DBA
PGPASSWORD=$DBAPASSWD
export PGPASSWORD

$SQLDBA -d $DATABASE -f extentions.sql

# Всё остальное делаем от имени нашего администратора
PGPASSWORD=$ADMINPASSWD
export PGPASSWORD

$SQL json.sql;
$SQL tools.sql;
$SQL test.sql;
$SQL seq.sql;
$SQL def.sql;
$SQL set.sql;
$SQL obj.sql;

$SQL public.sql;

PGPASSWORD=
export PGPASSWORD

cd $CUR_PATH
