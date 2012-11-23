#!/bin/bash

DATABASE=test
SQL_PATH=sql/
HOST=localhost
DBA=postgres
ADMIN=postgres


psql -h $HOST -U $DBA -f $SQLPATH database_create.sql;

psql -h $HOST -U $ADMIN -1 -d $DATABASE -f $SQLPATH ext.sql;
psql -h $HOST -U $ADMIN -1 -d $DATABASE -f $SQLPATH json.sql;
psql -h $HOST -U $ADMIN -1 -d $DATABASE -f $SQLPATH tools.sql;
psql -h $HOST -U $ADMIN -1 -d $DATABASE -f $SQLPATH test.sql;
psql -h $HOST -U $ADMIN -1 -d $DATABASE -f $SQLPATH seq.sql;
psql -h $HOST -U $ADMIN -1 -d $DATABASE -f $SQLPATH def.sql;

psql -h $HOST -U $ADMIN -1 -d $DATABASE -f $SQLPATH public.sql;
