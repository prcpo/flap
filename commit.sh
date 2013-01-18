#!/bin/bash

cd utils
./dump_schemas.sh

cd ..
git add .
git commit -e 
