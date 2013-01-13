#!/bin/sh

/opt/PostgreSQL/9.2/bin/pg_dump -h localhost -U postgres -F p -n $1 -O --column-inserts --inserts accounting | sed 's/^--.*//g' | grep '.' > ../sql/$1.sql
