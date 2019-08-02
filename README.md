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

* [JIRA board](https://bugs.library.illinois.edu/projects/MBT)

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

# Clone the repository
$ git clone https://github.com/medusa-project/book-tracker.git
$ cd book-tracker

# Install Ruby into rbenv
# (Note: `.ruby-version` is used by rbenv, but rbenv isn't used in Docker, so
# the version it contains must be kept in sync with the one used in the
# Dockerfile.)
$ rbenv install "$(< .ruby-version)"

# Install Bundler
$ gem install bundler

# Install the gems needed by the application
$ bundle install

# Configure the application
# After acquiring config/master.key from someone on the project team:
$ bin/rails credentials:edit

# Create and seed the database
$ bin/rails db:setup

# Add a user
$ bin/rails users:create <username>

# Start the server
$ bin/rails server
```

## Sign in

Navigate to `/signin` and sign in as the user you created, using
`username@example.org` as the password.

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

At UIUC, there are separate sets of Terraform scripts that provision the
production and demo environments:

* [Demo](https://code.library.illinois.edu/projects/TER/repos/aws-book-tracker-demo-service/browse)
* [Production](https://code.library.illinois.edu/projects/TER/repos/aws-book-tracker-prod-service/browse)

These scripts *don't* provision the RDS instances or the IAM application user,
which must be done manually.

Note that the task definition must contain the following environment variables:

* `RAILS_ENV` (`demo` or `production`)
* `SHIBBOLETH_HOST`

The application configuration also must be updated with all of the necessary
information:

```bash
$ bin/rails credentials:edit
```

Then, use the `rails-container-scripts` to build and deploy, typically via:

```bash
$ rails-container-scripts/docker-build.sh [demo or production]
$ rails-container-scripts/ecr-push.sh [demo or production]
$ rails-container-scripts/ecs-deploy-webapp.sh [demo or production]
```

## Import books & check tasks

The buttons in the web interface at `/tasks` send requests to the ECS API
to start tasks that invoke these various commands and then exit.
