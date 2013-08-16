#!/bin/sh

/opt/PostgreSQL/9.3/bin/pg_dump -h localhost -p 5433 -U postgres -F p -n $1 -O --column-inserts --inserts $2 test | sed 's/^--.*//g' | grep '.' > ../sql/$1.sql
