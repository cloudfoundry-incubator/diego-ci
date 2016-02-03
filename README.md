# Diego CI

Scripts and tools to run Diego's CI builds on Concourse.

# Configuring AWS for Cloud Foundry

1. Make sure the `id_rsa_bosh` keypair in the `keypair` directory matches the `bosh` key in AWS.
1. Create a Route 53 Hosted Zone for your desired subdomain.
1. If there aren't already an RSA key and self-signed certificate in your `DEPLOYMENT_DIR/certs/elb-<SOMETHING>.key`, generate them and put them there.  Update the `deploy` script to upload the correct certs.
1. If you are creating a new environment, and have copied an existing environments deployment directory, review the non-generated stubs (YAML files in the `stubs` directory that don't start with `#GENERATED, NO TOUCHING`) to make sure they make sense for your new environment.  In particular, there are several stubs that reference the environment name that will need to be updated.
1. Similarly, update the CloudFormation stack name in the `deploy` script to match your environment name.
1. If a `bootstrap_environment` file doesn't already exist, create one that looks like this:

   ```
   export AWS_DEFAULT_REGION=<fill-this-in>
   export AWS_ACCESS_KEY_ID=<fill-this-in>
   export AWS_SECRET_ACCESS_KEY=<fill-this-in>
   ```

1. Install bosh-init, following the instructions here: <https://bosh.io/docs/install-bosh-init.html>
1. Get dependencies:

   ```
   sudo easy_install pip
   pip install awscli
   go get -u github.com/vito/boosh
   ```
1. Run `./deploy`.
1. After running this the first time, you'll need to modify the `create-stack` cloudformation command to `update-stack`.  If there are no updates, you will need to remove (or comment out) that command as well as the subsequent `boosh watch` command.  Unfortunately, the AWS CLI is not idempotent.
1. After the script completes successfully, you will need to manually update the Route 53 A record for bosh-init to point to the associated Elastic IP.  This will allow you to target the BOSH director via DNS; alternatively you can target it directly via its Elastic IP.
1. Change the default admin/admin bosh credentials to something secret, and add it to LastPass.

### Requirements

* [Go 1.4.3](https://golang.org/dl/)

* [boosh](https://github.com/vito/boosh)
```
go get -u github.com/kr/godep
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




* [Ruby](https://www.ruby-lang.org/en/documentation/installation/) 

* [Bosh](http://bosh.io/) cli 
```
gem install bosh_cli
```

* [Bosh init](https://bosh.io/docs/install-bosh-init.html)

### Setup

You will need to create a local directory containing your private keys and passwords with the following format:
DEPLOYMENT_DIR
|-bootstrap_environment
|-certs
| |-(elb-cfrouter.key)
| |-(elb-cfrouter.pem)
|-teamplates
|-stubs
| |-(domain.yml)
| |-infrastructure
|   |-(availablity_zones.yml)  # available aws zones change whenever the heck they feel like it
