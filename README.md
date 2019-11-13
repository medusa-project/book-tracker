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

# Clone the repository
$ git clone https://github.com/medusa-project/book-tracker.git
$ cd book-tracker

# Install Ruby into rbenv
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

At UIUC, there are separate sets of Terraform scripts that provision the
production and demo environments:

* [Demo](https://code.library.illinois.edu/projects/TER/repos/aws-book-tracker-demo-service/browse)
* [Production](https://code.library.illinois.edu/projects/TER/repos/aws-book-tracker-prod-service/browse)

These scripts don't provision the RDS instances or the IAM application user,
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
$ rails-container-scripts/redeploy.sh <demo or production>
```

## Import books & check tasks

The buttons in the web interface at `/tasks` send requests to the ECS API
to start tasks that invoke these various commands and then exit.
