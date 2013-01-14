#!/bin/bash

./dump_schema.sh def;
#./dump_schema.sh ext;
./dump_schema.sh json;
./dump_schema.sh obj;
./dump_schema.sh public -s;
./dump_schema.sh sec;
./dump_schema.sh set -s;
./dump_schema.sh test -s;
./dump_schema.sh tools -s;

