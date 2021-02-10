#!/bin/bash
#
# Starts a remote sbatch jobs and sets up correct port forwarding.
# Sample usage: bash start.sh sherlock/singularity-jupyter 
#               bash start.sh sherlock/singularity-jupyter /home/users/raphtown
#               bash start.sh sherlock/singularity-jupyter /home/users/raphtown

while test $# -gt 0; do
  case "$1" in
    -h|--help)
      echo "$forward - set up port forwarding on slurm based computing resources"
      echo "options:"
      echo "-h, --help                show brief help"
      echo "-r, --resource=RESOURCE       specify an action to use"
      echo "-p, --partition=PARTITION      specify a directory to store output in"
      echo "-m, --memory=MEM       specify an action to use"
      echo "-t, --time=TIME      specify a directory to store output in"

      exit 0
      ;;
    -r)
      shift
      if test $# -gt 0; then
        export RESOURCE=$1
      else
        echo "no resource specified"
        exit 1
      fi
      shift
      ;;
    --resource*)
      export RESOURCE=`echo $1 | sed -e 's/^[^=]*=//g'`
      shift
      ;;
    -p)
      shift
      if test $# -gt 0; then
        export PARTITION=$1
      else
        echo "no partition specified"
        exit 1
      fi
      shift
      ;;
    --partition*)
      export PARTITION=`echo $1 | sed -e 's/^[^=]*=//g'`
      shift
      ;;
    -m)
      shift
      if test $# -gt 0; then
        export MEM=$1
      else
        echo "no memory specified"
        exit 1
      fi
      shift
      ;;
    --memory*)
      export MEM=`echo $1 | sed -e 's/^[^=]*=//g'`
      shift
      ;;
    -t)
      shift
      if test $# -gt 0; then
        export TIME=$1
      else
        echo "no time specified"
        exit 1
      fi
      shift
      ;;
    --time*)
      export TIME=`echo $1 | sed -e 's/^[^=]*=//g'`
      shift
      ;;
    -n)
      shift
      if test $# -gt 0; then
        export NAME=$1
      else
        echo "no sbatch script specified"
        exit 1
      fi
      shift
      ;;
    --name*)
      export NAME=`echo $1 | sed -e 's/^[^=]*=//g'`
      shift
      ;;
    *)
      break
      ;;
  esac
done

echo "# resource: $RESOURCE"
echo "# partition: $PARTITION"
echo "# memory: $MEM"
echo "# time: $TIME"
echo "# name: $NAME"

if [ ! -f params.sh ]
then
    echo "Need to configure params before first run, run setup.sh!"
    exit
fi
. params.sh

#if [ "$#" -eq 0 ]
#then
#    echo "Need to give name of sbatch job to run!"
#    exit
#fi

if [ ! -f helpers.sh ]
then
    echo "Cannot find helpers.sh script!"
    exit
fi
. helpers.sh

#NAME="${1:-}"

# The user could request either <resource>/<script>.sbatch or
#                               <name>.sbatch
SBATCH="$NAME.sbatch"

# set FORWARD_SCRIPT and FOUND
set_forward_script
check_previous_submit

echo
echo "== Getting destination directory =="
RESOURCE_HOME=`ssh ${RESOURCE} pwd`
ssh ${RESOURCE} mkdir -p $RESOURCE_HOME/forward-util

echo
echo "== Uploading sbatch script =="
scp $FORWARD_SCRIPT ${RESOURCE}:$RESOURCE_HOME/forward-util/

# adjust PARTITION if necessary
set_partition
echo

echo "== Submitting sbatch =="

SBATCH_NAME=$(basename $SBATCH)
command="sbatch
    --job-name=$NAME
    --partition=$PARTITION
    --output=$RESOURCE_HOME/forward-util/$SBATCH_NAME.out
    --error=$RESOURCE_HOME/forward-util/$SBATCH_NAME.err
    --mem=$MEM
    --time=$TIME
    $RESOURCE_HOME/forward-util/$SBATCH_NAME $PORT \"${@:2}\""

echo ${command}
ssh ${RESOURCE} ${command}

# Tell the user how to debug before trying
instruction_get_logs

# Wait for the node allocation, get identifier
get_machine
echo "notebook running on $MACHINE"

setup_port_forwarding

sleep 10
echo "== Connecting to notebook =="

# Print logs for the user, in case needed
print_logs

echo

instruction_get_logs
echo
echo "== Instructions =="
echo "1. Password, output, and error printed to this terminal? Look at logs (see instruction above)"
echo "2. Browser: http://sh-02-21.int:$PORT/ -> http://localhost:$PORT/..."
echo "3. To end session: bash end.sh ${NAME}"
