#!/bin/bash

PORT=$1
NOTEBOOK_DIR=${2:-${SCRATCH}}
cd $NOTEBOOK_DIR

Conda activate
module load py-jupyter/1.0.0_py36
jupyter lab --no-browser --port=$PORT
