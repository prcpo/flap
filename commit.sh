#!/bin/bash

COMMENT=$@

cd utils
./dump_schemas.sh

cd ..
git add .
git commit -m '$COMMENT'
