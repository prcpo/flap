#!/bin/bash

echo def...
./dump_schema.sh def;
#./dump_schema.sh ext;
echo json...
./dump_schema.sh json;
echo obj...
./dump_schema.sh obj;
echo public...
./dump_schema.sh public -s;
echo sec...
./dump_schema.sh sec -s;
echo set...
./dump_schema.sh set -s;
echo test...
./dump_schema.sh test -s;
echo tools...
./dump_schema.sh tools -s;

