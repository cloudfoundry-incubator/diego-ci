#!/usr/bin/env bash

PIPELINE=$1
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
FLY_EXE=$(which fly)
if type -p "fly-hush-house" > /dev/null; then
  FLY_EXE=$(which fly-hush-house)
fi
lpass status 2>&1 > /dev/null;
if [[ $? -eq 0 ]]; then
  "$FLY_EXE" -t ${DIEGO_CI_TARGET:-diego-ci} sp -p "$PIPELINE" -c "$DIR/../pipelines/$PIPELINE.yml" --load-vars-from <(lpass show --notes "diego-pipeline-secrets")
else
  echo "Login to lastpass: 'lpass login ...'";
fi
