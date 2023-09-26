The Book Tracker is a database of local book holdings that can be cross-
referenced with inventories in HathiTrust, Internet Archive, and "corporate
partners."

The main component is a Rails application that provides the website. Separate
tasks exist to:
 
1. Scan an S3 bucket for MARCXML files, read and parse each one, and store the
   results in a database table.
2. Iterate over the database rows, check various external services for matching
   records, and update the database with their findings.

In development, these run as rake tasks. In production, they run as Fargate
tasks invoked via the ECS API.

# Quick links

* [SCARS Wiki](https://wiki.illinois.edu/wiki/display/scrs/Book+Tracker)
* [JIRA project](https://bugs.library.illinois.edu/projects/MBT)

# Dependencies

* PostgreSQL >= 9.x

# Development

## Prepare a development environment

```bash
# Install rbenv

$ brew install rbenv
$ brew install ruby-build
$ brew install rbenv-gemset --HEAD
$ rbenv init
$ rbenv rehash

# Clone the repository and submodules
$ git clone --recurse-submodules https://github.com/medusa-project/book-tracker.git
$ cd book-tracker

# Install Ruby into rbenv
$ rbenv install "$(< .ruby-version)"

# Install Bundler
$ gem install bundler

# Install the gems needed by the application
$ bundle install

# Configure the application
$ cp config/credentials/template.yml config/credentials/development.yml
$ cp config/credentials/template.yml config/credentials/test.yml
# (Fill in both of the above files.)

# Create and seed the database
$ bin/rails db:setup

# Start the server
$ bin/rails server
```

## Sign in

Navigate to `/signin` and sign in as `admin` using `admin@example.org` as the
password.

## Import books

```bash
$ bin/rails books:import
```

## Check services

```bash
$ bin/rails books:check_google
$ bin/rails books:check_hathitrust
$ bin/rails books:check_internet_archive
```

# Production

At UIUC, this application runs in AWS ECS. There are separate sets of Terraform
scripts that provision the demo and production environments:

* [Demo](https://code.library.illinois.edu/projects/TER/repos/aws-book-tracker-demo-service/browse)
* [Production](https://code.library.illinois.edu/projects/TER/repos/aws-book-tracker-prod-service/browse)

(These scripts don't provision the RDS instances or the IAM application user,
which must be done manually.)

The application configuration also must be updated with all of the necessary
information:

```bash
$ bin/rails credentials:edit -e demo
$ bin/rails credentials:edit -e production
```

Then, use the `rails-container-scripts` submodule to build and deploy. These
are basically just wrapper scripts around Docker and
[awscli](https://aws.amazon.com/cli/), so those must be installed first.

```bash
$ rails-container-scripts/redeploy.sh <demo or production>
```

Note that when you try to build an image for the first time from an ARM Mac,
you may get an error message like:

```
ERROR: Multiple platforms feature is currently not supported for docker driver.
Please switch to a different driver (eg. "docker buildx create --use")
```

In this case, do what the message suggests, and run
`docker buildx create --use`. You will only have to do it once.

## Import books & check tasks

The buttons in the web interface at `/tasks` send requests to the ECS API
to start tasks that invoke the various `books:*` rake tasks and then exit.
