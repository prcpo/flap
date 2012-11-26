#!/bin/bash

DATABASE=test
HOST=localhost
DBA=postgres
ADMIN=postgres
TMP_PATH=/tmp
CUR_PATH=$PWD

cd sql


psql -h $HOST -U $DBA -f database_create.sql;

psql -h $HOST -U $ADMIN -1 -d $DATABASE -f ext.sql;
psql -h $HOST -U $ADMIN -1 -d $DATABASE -f json.sql;
psql -h $HOST -U $ADMIN -1 -d $DATABASE -f tools.sql;
psql -h $HOST -U $ADMIN -1 -d $DATABASE -f test.sql;
psql -h $HOST -U $ADMIN -1 -d $DATABASE -f seq.sql;
psql -h $HOST -U $ADMIN -1 -d $DATABASE -f def.sql;

psql -h $HOST -U $ADMIN -1 -d $DATABASE -f public.sql;

cd ..