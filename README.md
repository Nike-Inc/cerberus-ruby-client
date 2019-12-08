# Cerberus Ruby Client (Depricated)

This project is depricated and probably doesn't work with the current API.

[![Gem](https://img.shields.io/gem/v/cerberus_client.svg)](https://rubygems.org/gems/cerberus_client)
[![Downloads](https://img.shields.io/gem/dt/cerberus_client.svg)](https://rubygems.org/gems/cerberus_client)
[![Build](https://travis-ci.org/Nike-Inc/cerberus-ruby-client.svg?branch=master)](https://travis-ci.org/Nike-Inc/cerberus-ruby-client)

This is a Ruby based client library for communicating with Ceberus via HTTP and enables authentication schemes specific
to AWS and Cerberus.

This client currently supports read-only operations (write operations are not yet implemented, feel free to open a
pull request to implement write operations)

To learn more about Cerberus, please visit the [Cerberus website](http://engineering.nike.com/cerberus/).

## Installation

These installation instructions need to be updated after we open source and publish the gems somewhere public

Add this to your application's Gemfile:

```ruby
source 'https://rubygems.org'
gem 'cerberus_client'
```

And then install it:
```bash
$ bundle
```

Or do it yourself:
```bash
$ gem install cerberus_client
```

## Usage

Please start by reading the [Cerberus quick start guide](http://engineering.nike.com/cerberus/docs/user-guide/quick-start).

```ruby
cerberus_client = CerberusClient::get_default_cerberus_client()
```

```ruby
cerberus_client = CerberusClient::get_cerberus_client_for_assumed_role(Cerberus::DefaultUrlResolver.new, "arn:aws:iam::<account_id>:role/<role_name>", "us-west-2")
```

There are two ways Cerberus clients are typically used:

1. Local Development using environmental variables created using [cerberus-token.sh](https://raw.githubusercontent.com/Nike-Inc/cerberus/master/docs/user-guide/cerberus-token.sh)
2. Running in AWS using [EC2 instance or Lambda Authentication](http://engineering.nike.com/cerberus/docs/architecture/authentication)

### Local Development

The example Ruby code above uses the DefaultUrlResolver to resolve the URL for Cerberus. For that to succeed, the
environment variable, CERBERUS_ADDR, must be set:
```bash
export CERBERUS_ADDR=https://cerberus.example.com
```
OR
```bash
export CERBERUS_ADDR=https://localhost:9001
```

The example above also use the DefaultCredentialsProviderChain which is used to resolve the token needed to interact
with Cerberus. This chain will first look to see if an environemnt variable has been set with a cerberus token, e.g.
```bash
export CERBERUS_TOKEN=9cfced14-91ae-e3ad-5b9d-1cae6c82362d
```

Increment the version and add `.rc.1` to the end in the `lib/cerberus_utils/version.rb` file.

Then build and install the gem locally:

```bash
% gem build cerberus_client.gemspec
Successfully built RubyGem
Name: cerberus_client
Version: 0.0.0.rc.1
File: cerberus_client-0.0.0.rc.1

% gem install ./cerberus_client-0.0.0.rc.1.gem
Successfully installed cerberus_client-0.0.0.rc.1
1 gem installed
```

Then open Interactive Ruby:
```bash
% irb

2.2.2 :001 > require 'cerberus_client'
2.2.2 :001 > vaultClient = CerberusClient::get_default_vault_client()
2.2.2 :001 > vaultClient.read("app/example/test")
```

** Note: If a `LoadError` is thrown with a message `cannot load such file` this may be because
you have added new files. Commit the new files and re-build your gem to ensure the new files
get included in your gem release candidate  .

### Run Tests Locally

```bash
% gem install rspec
```

Then in the top-level project directory, run

```bash
% rspec spec
```

### Running in AWS

If the environment variables used in local development are not found, the client will try to use the AWS metadata
service and instance metadata to authenticate with Cerberus using the IAM role assigned to the instance.  Instructions
are available in the [Cerberus quick start guide](http://engineering.nike.com/cerberus/docs/user-guide/quick-start).

Optionally, UrlResolver and/or CredentialsProviderChain can be provided to customize how those values are used in
your system. See lib/cerberus_client for alternative factory methods and the functions your custom objects should
support.
