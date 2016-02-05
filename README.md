# Diego CI

Scripts and tools to run Diego's CI builds on Concourse.

# AWS Requirments

1. Create a local directory which will be used to store private keys. From here on, we will refer to
   this direcotry as `DEPLOYMENT_DIR`.

1. <span id="create-aws-keypair">Create an AWS keypair for yout bosh director</span>
  a.  From your aws EC2 page click on the `Key Pairs` tab
  b.  Select the `create keypair` button at the top of the page
  c.  When prompted for the key name, enter `bosh`
  d.  Move the downloaded `bosh.pem` key to `DEPLOYMENT_DIR/keypair/` and rename the key to `id_rsa_bosh` 
  
1. <span id="create-route-53">Create Route 53 Hosted Zone</span>
  a.  From the aws console homepage click on `Route 53`
  b.  Select `hosted zones` from the left sidebar
  c.  Click the `Create Hosted Zone` button
  d.  Fill in the domain name of your cloud foundry deployment
  Note: The domain name will be the root path of all apps deployed on your cloud foundry.
  Ex:
  ```
    domain = foo.bar.com
    app name = `hello-world`. This will create a default route of hello-world.domain

    http://hello-world.foo.bar.com will be the root url address of your application
   ```

### System Requirements

* [Go 1.4.3](https://github.com/kr/godep.git)
* [godep](https://github.com/tools/godep)
```
go get -u github.com/kr/godep
```
* [boosh](https://github.com/vito/boosh)
```
godep get github.com/vito/boosh
```
* [spiff](https://github.com/cloudfoundry-incubator/spiff)
```
godep get github.com/cloudfoundry-incubator/spiff
```
* The [aws cli](https://aws.amazon.com/cli/) requires python and pip to be installed
on your host machine.
```
pip install awscli
```
* [jq version 1.5+](https://stedolan.github.io/jq/)
* [Ruby 2+](https://www.ruby-lang.org/en/documentation/installation/) 
* [Bosh](http://bosh.io/) cli 
```
gem install bosh_cli
```
* [Bosh init](https://bosh.io/docs/install-bosh-init.html)

### Setup

You will need to create a local directory containing your private keys and passwords with the following format:
```
DEPLOYMENT_DIR
|-(bootstrap_environment)
|-keypair
| |-(id_rsa_bosh)
|-certs
| |-(elb-cfrouter.key)
| |-(elb-cfrouter.pem)
|-stubs
| |-(domain.yml)
| |-infrastructure
| | |-(availablity_zones.yml)  # available aws zones change whenever the heck they feel like it
| |-bosh-init
|   |-(releases.yml)
|   |-(users.yml)
|   |-(stemcell.yml)
```

#### bootstrap_environment

This file contains exportable environment variables your aws default region and access/secret keys.
The `AWS_ACCESS_KEY_ID` key must match your aws IAM user's access key id and the `AWS_SECRET_ACCESS_KEY`
is the private key generated during the IAM user creation.
 
Ex:
```
export AWS_DEFAULT_REGION=us-east-1
export AWS_ACCESS_KEY_ID=xxxxxxxxxxxxxxxxxxx
export AWS_SECRET_ACCESS_KEY='xxxxxxxxxxxxxxxxxxxxxx'
```

#### keypair/id_rsa_bosh

This is a private key pair generated for our BOSH vm.  Please refer above to [creating an AWS keypair for your Bosh director](#create-aws-keypair).

#### certs/elb-cfrouter.key && certs/elb-cfrouter.pem
An SSL certificate for the domain where Cloud Foundry will be accessible is required. If you do not provide a certificate,
you can generate a self signed cert following the commands below:

```
openssl genrsa -out elb-cfrouter.key 2048
openssl req -new -key elb-cfrouter.key -out elb-cfrouter.csr
openssl x509 -req -in elb-cfrouter.csr -signkey elb-cfrouter.key -out elb-cfrouter.pem
```

#### stubs/domain.yml

The `domain.yml` should be assigned to the domain generated in the [create route 53 hosted zone](#create-route-53)

Ex:
```
---
domain: <your-domain.com>
```

#### stubs/infrastructure/availability_zones.yml

This yaml file defines the 3 zones that will host your Cloud Foundry Deployment.

Ex:
```
meta:
  availability_zones:
    - us-east-1a
    - us-east-1c
    - us-east-1d
``` 

Note: These zones could become restricted by AWS. If at some point during the deploy script and you see an error
with the following message: "Value (us-east-1b) for parameter availabilityZone is invalid. Subnets can currently
only be created in the following availability zones: us-east-1d, us-east-1b, us-east-1a, us-east-1e." You will need
to update this fille with allowd values.

#### stubs/bosh-init/releases.yml

The bosh-init's `releases.yml` requires specific `bosh` and `bosh-aws-cpi` proprties and can be seen in the following example.

Ex:
```
releases:
  - name: bosh
    url: https://bosh.io/d/github.com/cloudfoundry/bosh?v=210
    sha1: 0ff01bfe8ead91ff2c4cfe5309a1c60b344aeb09
  - name: bosh-aws-cpi
    url: https://bosh.io/d/github.com/cloudfoundry-incubator/bosh-aws-cpi-release?v=31
    sha1: bde15dfb3e4f1b9e9693c810fa539858db2bc298
```
 
The properties for `bosh` can be found [here](http://bosh.io/releases/github.com/cloudfoundry/bosh?all=1) and the properties 
can be found [here](http://bosh.io/releases/github.com/cloudfoundry-incubator/bosh-aws-cpi-release?all=1).   

#### stubs/bosh-init/users.yml

This yaml file defines the admin user to be created for your bosh director with admin privlages. In this file you
are able to define any number of users that you want.

Ex:
```
bosh-init:
  users:
    - {name: admin, password: YOUR_PASSWORD}
    - {name: second_admin, password: YOUR_SECOND_PASSWORD} # this user on anny additional user are not required
```

#### stubs/bosh-init/stemcell.yml

Stemcell.yml defines which stemcell to use on the bosh director. The stemcells can be found
[here](http://bosh.io/stemcells/bosh-aws-xen-ubuntu-trusty-go_agent) and formatted to the 
following example.

Ex:
```
stemcell:
  url: https://bosh.io/d/stemcells/bosh-aws-xen-hvm-ubuntu-trusty-go_agent?v=3091
  sha1: 21ce6eb039179bb5b1706adfea4c161ea20dea1f 
```

# Creating the CF AWS environment

To create the AWS environment and a couple of VMs essential to the Cloud Foundry infrastructure,
you will need to run `./deploy_aws_environment create DEPLOYMENT_DIR` from this repository.

The first argument can be one of: create, update, skip. The dirst time our script runs, passing create
will dynamically create an AWS Cloud Formation Stack based off of a few of the provided stubs. On subsequent
runs of this script, you will only want to provide `update` if any stubs under DEPLOYMENT_DIR/stubs/infrastructure
change, or there was an update to this repository. Otherwise you will want to run the script with `skip` so
that no changes are applid to the AWS environment.

The second parameter is you DEPLOYMENT_DIR and must be structured as the image above. During our deployment process
we will generate a few additional stubs and they will include the line "GENERATED NO TOUCHING" at the top of the files.

Outputs:
```
deployment_dir
|-stubs
| |-(directort-uuid.yml)
| |-(aws-resources.yml)
| |-cf
| | |-(aws.yml)
| |-infrastructure
|   |-(certificates.yml)
|   |-(cloudformation.json)
|-deployments
| |-bosh-init
|   |-(bosh-init.yml)
```

# Deploying CF

To deploy Cloud Foudry against your newly created AWS environment we need to generate a manifest for our deployment.
The instructions for full manifest genration can be found [here](http://docs.cloudfoundry.org/deploying/common/create_a_manifest.html),
but the part we are most concerned with is "Create a Deployment Manifest Stub" as we already have a `director-uuid.yml` stub
generated as part of our script output.

We need to create a stub which looks like the one from the Cloud Foundry Documentation
[here](http://docs.cloudfoundry.org/deploying/aws/cf-stub.html) with a few minor tweaks. Not to fret thought,
after creating our AWS environment from the step above we should have a generated `DEPLOYMENT_DIR/stubs/cf/aws.yml`
which can be used as a starting point for generating a similar stub. This stubhas some additional properties which
can be used to deploy CF across 3 zones insted of the 2 as shown in the Cloud Foundry Docs. Don't worry about that
extra information, just ensure that you provide all of the missing fields.

Lastly, default manifest generation will create/remove some additional VMs and unneeded properties such as the DEAs
when deploying diego. To correct these issues we can use the provided cf stub under `stubs/cf/diego.yml` when generating
the manifest.

After following the instructions to generate the stub and download the cf-release direcotry, we can run
the following command from this directory to generate our CF manifest:
```
CF-RELEASE_DIRECTORY/scripts/generate_deployment_manifest aws \
DEPLOYMENT_DIR/stubs/director_uuid.yml \
DEPLOYMENT_DIR/stubs/cf/aws.yml ./stubs/cf/diego.yml \
> DEPLOYMENT_DIR/deployments/cf.yml
```

From here following the [deploy](http://docs.cloudfoundry.org/deploying/common/deploy.html) steps should be the only thing
left to do. Just remember to use our generated deployment manifest with the command `bosh deployment DEPLOYMENT_DIR/deployment/cf.yml`.

# Deploying Diego

To deploy Diego follow the instructions on the [Diego Release](https://github.com/cloudfoundry-incubator/diego-release) page.
