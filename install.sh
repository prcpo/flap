#!/bin/bash

# Имя создаваемой базы данных
DATABASE=test

# IP адрес или имя сервера.
HOST=localhost

# Порт сервера
PORT=5433

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

SQLFILE=$TMP_PATH/install_db.sql
OUTFILE=$TMP_PATH/install_db.log

SQL='psql -e -h '$HOST' -p '$PORT' -U '$ADMIN' -1 -d '$DATABASE' -f'
SQLDBA='psql -e -h '$HOST' -p '$PORT' -U '$DBA 


function dofile {
    echo $1 ...;
    echo '-- FILE: ' $1 >> $SQLFILE ;
    cat $1 >> $SQLFILE;
#    $SQL $1 >>$OUTFILE 2>&1;
    echo '---------------' >> $SQLFILE;
}

echo '' > $OUTFILE;
echo '' > $SQLFILE;

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

dofile ext.sql;

# Чтобы добавить расширения в схему ext опять нужны права DBA
PGPASSWORD=$DBAPASSWD
export PGPASSWORD;

echo extensions...
$SQLDBA -d $DATABASE -f extentions.sql;

# Всё остальное делаем от имени нашего администратора
PGPASSWORD=$ADMINPASSWD
export PGPASSWORD;

echo roles.sql;
$SQL roles.sql >>$OUTFILE 2>&1;

dofile json.sql;
dofile tools.sql;
dofile set.sql;
dofile def.sql;
dofile test.sql;
dofile sec.sql;
dofile obj.sql;
dofile public.sql;

$SQL $SQLFILE >>$OUTFILE 2>&1;

PGPASSWORD=
export PGPASSWORD;

cd $CUR_PATH;

echo 
echo 'ОШИБОК при установке: ' `grep -c "ERROR" $OUTFILE`
echo 'Подробности установки в файле ' $OUTFILE
echo 

