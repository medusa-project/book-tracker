The Book Tracker scans an S3 bucket for MARCXML files, reads and parses each
one, and stores the results in a database table. Several asynchronous tasks
iterate over the database rows and check various external services (HathiTrust,
Internet Archive, etc.) for matching records, updating the database with their
findings.

This is a Rails application. `rails server` runs the web application, and
various rake tasks run the tasks.

# Quick links

* [JIRA board](https://bugs.library.illinois.edu/projects/MBT)

# Dependencies

* PostgreSQL 9.x

# Preparing a development environment

## 1) Install RVM:

`$ \curl -sSL https://get.rvm.io | bash -s stable`

`$ source ~/.bash_profile`

## 2) Clone the repository:

```
$ git clone https://github.com/medusa-project/book-tracker.git
$ cd book-tracker
```

## 3) Install Ruby

`$ rvm install "$(< .ruby-version)" --autolibs=0`

## 4) Install Bundler

`$ gem install bundler`

## 5) Install the gems needed by the application:

`$ bundle install`

## 6) Configure the application

Open `config/book_tracker.yml` and `config/database.yml` and add the
environment variables referenced within to your environment.

## 7) Create and seed the database

`$ bin/rails db:setup`

# Upgrading

`bin/rails db:migrate`

# Usage

## Importing books

In development, run an import task from the command line:

`$ bin/rails books:import`

In production, the buttons in the web interface at `/tasks` will send a request
to the ECS API to start a task (container, more or less) that invokes the above
command and then exits.

## Checking services

In development, run an import task from the command line:

```
$ bin/rails books:check_google
$ bin/rails books:check_hathitrust
$ bin/rails books:check_internet_archive
```

Same idea as "importing books" in production.

# Docker

## Locally

Fill in `env.list`. Then, build the container:

`./docker-build.sh`

And either run the server:

`./docker-run-server.sh`

Or a task (see `bin/rails -T` for a list):

`./docker-run-task.sh books:import`

## In production

`env.list` is not used in production. Instead, its variables are added to the
ECS task definition.

Then, build the container:

`./docker-build.sh`

Push the image to ECR:

`./ecr-push.sh`

Run it:

`./ecs-deploy.sh`

# Notes

## Using Shibboleth locally

Log in as:
* `admin`/`admin@example.org` for admin privileges
* `user`/`user@example.org` for normal-user privileges
