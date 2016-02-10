# Diego CI

This repository contains tools to deploy Diego to AWS environments as well as our concourse scripts.

## Deploying Cloud Foundry and Diego to AWS

### Local System Requirements

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

### AWS Requirements

1. Create a local directory which will be used to store your deployment-specific credentials. From here on,
   this directory will be refered to as `DEPLOYMENT_DIR`.

1. Create IAM User
  1.  From the AWS console homepage, click on `Identity & Access Management`
  2.  Click on `Users` link
  3.  Click on the button `Create New Users`
  4.  Fill in only one user name
  5.  Make sure that the `Generate an access key for each user` checkbox is checked and click `Create`
  6.  Click `Download Credentials` at the bottom of the screen.

1. Create an AWS keypair for yout bosh director
  1.  From your AWS EC2 page click on the `Key Pairs` link
  2.  Click the `Create Key Pair` button at the top of the page
  3.  When prompted for the key name, enter `bosh`
  4.  Move the downloaded `bosh.pem` key to `DEPLOYMENT_DIR/keypair/` and rename the key to `id_rsa_bosh`

1. Create Route 53 Hosted Zone
  1.  From the aws console homepage, click on `Route 53`
  2.  Select `Hosted zones` from the left sidebar
  3.  Click the `Create Hosted Zone` button
  4.  Fill in the domain name for your cloud foundry deployment

  By default, the domain name for your hosted zone will be the root domain of all apps deployed to your cloud foundry instance.

  eg:
   ```
   domain = foo.bar.com
   app name = `hello-world`. This will create a default route of hello-world.domain

   http://hello-world.foo.bar.com will be the root url address of your application
   ```

### System Setup

Your DEPLOYMENT_DIR needs to have the following the following format. Each of the files is further explained below.
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

This script should export your aws default region and access/secret keys as environment variables.
The `AWS_ACCESS_KEY_ID` key must match your aws IAM user's access key id and the `AWS_SECRET_ACCESS_KEY`
is the private key generated during the [IAM user creation](#aws-requirements).

eg:
```
export AWS_DEFAULT_REGION=us-east-1
export AWS_ACCESS_KEY_ID=xxxxxxxxxxxxxxxxxxx
export AWS_SECRET_ACCESS_KEY='xxxxxxxxxxxxxxxxxxxxxx'
```

#### keypair/id_rsa_bosh

This is the private key pair generated for the BOSH director when the [AWS keypair](#aws-requirements) was created.

#### certs/elb-cfrouter.key && certs/elb-cfrouter.pem
An SSL certificate for the domain where Cloud Foundry will be accessible is required. If you do not already provide a certificate,
you can generate a self signed cert following the commands below:

```
openssl genrsa -out elb-cfrouter.key 2048
openssl req -new -key elb-cfrouter.key -out elb-cfrouter.csr
```
You can leave all of the requested inputs blank. Then run:

```
openssl x509 -req -in elb-cfrouter.csr -signkey elb-cfrouter.key -out elb-cfrouter.pem
```

#### stubs/domain.yml

The `domain.yml` should be assigned to the domain that was generated when the [route 53 hosted zone](#aws-requirements) was created.

eg:
```
---
properties:
  domain: <your-domain.com>
```

#### stubs/infrastructure/availability_zones.yml

This yaml file defines the 3 zones that will host your Cloud Foundry Deployment.

eg:
```
meta:
  availability_zones:
    - us-east-1a
    - us-east-1c
    - us-east-1d
```

Note: These zones could become restricted by AWS. If at some point during the `deploy_aws_cli` script and you see an error
similar to the following message:

```
Value (us-east-1b) for parameter availabilityZone is invalid
Subnets can currently only be created in the following availability zones:
us-east-1d, us-east-1b, us-east-1a, us-east-1e
```
you will need to update this file with acceptable availability zone values.

#### stubs/bosh-init/releases.yml

To deploy the bosh director, bosh-init's `releases.yml` must specify `bosh` and `bosh-aws-cpi` releases by `url` and `sha1`.

eg:
```
releases:
  - name: bosh
    url: https://bosh.io/d/github.com/cloudfoundry/bosh?v=210
    sha1: 0ff01bfe8ead91ff2c4cfe5309a1c60b344aeb09
  - name: bosh-aws-cpi
    url: https://bosh.io/d/github.com/cloudfoundry-incubator/bosh-aws-cpi-release?v=31
    sha1: bde15dfb3e4f1b9e9693c810fa539858db2bc298
```

Releases for `bosh` can be found [here](http://bosh.io/releases/github.com/cloudfoundry/bosh?all=1).
Releases for `bosh-aws-cpi` can be found [here](http://bosh.io/releases/github.com/cloudfoundry-incubator/bosh-aws-cpi-release?all=1).

#### stubs/bosh-init/users.yml

This file defines the admin users for your bosh director.

eg:
```
BoshInitUsers:
  - {name: admin, password: YOUR_PASSWORD}
```

#### stubs/bosh-init/stemcell.yml

This file defines which stemcell to use on the bosh director. Stemcells can be found
[here](http://bosh.io/stemcells/bosh-aws-xen-ubuntu-trusty-go_agent), and must be specified by their `url` and `sha1`.

eg:
```
BoshInitStemcell:
  url: https://bosh.io/d/stemcells/bosh-aws-xen-hvm-ubuntu-trusty-go_agent?v=3091
  sha1: 21ce6eb039179bb5b1706adfea4c161ea20dea1f
```

### Creating the Cloud Foundry AWS environment

To create the AWS environment and two VMs essential to the Cloud Foundry infrastructure,
**from this repository**, you need to run `./deploy_aws_environment create DEPLOYMENT_DIR`. This may take up to 30 minutes.

The `./deploy_aws_environment` script has three possible actions.
  * `create` spins up an AWS Cloud Formation Stack based off of the stubs filled out above
  * run `update` if you change your stubs under DEPLOYMENT_DIR/stubs/infrastructure or there was an update to this repository
  * `skip` will upgrade your bosh director, but will not touch the AWS environment

The second parameter is your DEPLOYMENT_DIR and must be structured as defined above. The deployment process
generates additional stubs that include the line "GENERATED: NO TOUCHING".

The generated stubs are:
```
deployment_dir
|-stubs
| |-(director-uuid.yml) # the bosh director's unique id
| |-(aws-resources.yml)  # general metadata about our cloudformation deployment
| |-cf
| | |-(aws.yml) # networks, zones, s3 buckets for our Cloud Foundry deployment
| |-infrastructure
|   |-(certificates.yml) # for our aws-provided elb
|   |-(cloudformation.json) # aws' deployed cloudformation.json
|-deployments
| |-bosh-init
|   |-(bosh-init.yml) # bosh director deployment
```

### Deploying Cloud Foundry

### Clone `cf-release`

Clone [cf-release](https://github.com/cloudfoundry/cf-release) to your local system. This directory will be
refered to as `CF_RELEASE_DIRECTORY`.

### Generate Manifest

To deploy Cloud Foundry, you need a stub similar to the one from the [Cloud Foundry Documentation](http://docs.cloudfoundry.org/deploying/aws/cf-stub.html).
The generated stub `DEPLOYMENT_DIR/stubs/cf/aws.yml` already has a number of these properties filled out for you. However, the generated stub has some
additional properties that can be used to deploy Cloud Foundry across 3 zones instead of 2, as shown in the Cloud Foundry Docs.
Don't worry about that extra information, just follow along with the Cloud Foundry
[editing instructions](http://docs.cloudfoundry.org/deploying/aws/cf-stub.html#editing) and fill in any properties that aren't already specified.

Cloud Foundry Documention manifest generation doesn't create some VMs and properties that Diego depends on It also includes some unnecessary VMs and properties that Diego doesn't need. To correct this, the provided cf stub `./stubs/cf/diego.yml` is used when generating the Cloud Foundry manifest.

After following the instructions to generate a `cf/aws.yml` stub and downloading the cf-release directory, run
the following command **inside this repository** to generate the Cloud Foundry manifest:
```
CF_RELEASE_DIRECTORY/scripts/generate_deployment_manifest aws \
DEPLOYMENT_DIR/stubs/director-uuid.yml \
DEPLOYMENT_DIR/stubs/cf/aws.yml ./stubs/cf/diego.yml \
> DEPLOYMENT_DIR/deployments/cf.yml
```

### Finally Actually Deploy

Login to BOSH with the following command:
```
bosh login
```
When prompted for the username and password, they are the credentials set in the `DEPLOYMENT_DIR/stubs/bosh-init/users.yml` stub.

Set the deployment manifest with the following command:
```
bosh deployment DEPLOYMENT_DIR/deployments/cf.yml
```

From here, follow the documentation on [deploying a Cloud Foundry with BOSH](http://docs.cloudfoundry.org/deploying/common/deploy.html). Note that the deployment
can take up to 30 minutes.

### Deploying Diego

To deploy Diego follow the instructions on the [Diego Release](https://github.com/cloudfoundry-incubator/diego-release) page.
