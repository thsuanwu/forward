#!/bin/bash

PORT=$1
NOTEBOOK_DIR=$2
cd $NOTEBOOK_DIR

source activate scanpy
jupyter lab --no-browser --port=$PORT
