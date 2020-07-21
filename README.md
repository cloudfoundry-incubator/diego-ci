# Diego CI

Scripts and tools to run Diego's CI builds on [Concourse CI](https://concourse-ci.org).

## What's in here
This repo contains:

- `manifests`: to deploy concourse workers to https://hush-house.pivotal.io
- `ops-files`: to update cf-deployment borrowed from toolsmiths
- `pipelines`: to create
  [main](https://hush-house.pivotal.io/teams/diego/pipelines/) and
  [docker](https://hush-house.pivotal.io/teams/diego/pipelines/docker) pipelines
- `scripts`: to set/update pipelines
- `tasks`: set of tasks used to supply diego & docker pipelines
- `templates`: integration-config templates used for running CATS
- `vars-files`: list of vars files used for deploy

## What do these tests do?
The tests for several sections of the pipeline, along with brief descriptions of what they test can be found in the following places. Some of these are submoduled into diego-release and others are not. 

- [cf-acceptance-tests](https://github.com/cloudfoundry/cf-acceptance-tests) (CATS)
- [smoke-tests](https://github.com/cloudfoundry/cf-smoke-tests)
- [inigo](https://github.com/cloudfoundry/inigo) - submoduled into diego-release
- [vizzini](https://github.com/cloudfoundry/vizzini) - submoduled into diego-release
