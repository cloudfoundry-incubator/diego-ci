#!/usr/bin/env bash

#diego_ci_target=https://diego.ci.cf-app.com
pipeline=PRs

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
FLY_EXE=$(which fly)
if type -p "fly-diego-ci" > /dev/null; then
  FLY_EXE=$(which fly-diego-ci)
fi
lpass status 2>&1 > /dev/null;
if [[ $? -eq 0 ]]; then
  "$FLY_EXE" -t ${DIEGO_CI_TARGET:-ci} sp -p ${pipeline} -c $DIR/../pipelines/diego-pr-pipeline.yml --load-vars-from <(lpass show --notes "diego-pipeline-secrets") "$@"
else
  echo "Login to lastpass: 'lpass login ...'";
fi
