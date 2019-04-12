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

# Development

## Prepare a development environment

```
# Install RVM
$ \curl -sSL https://get.rvm.io | bash -s stable
$ source ~/.bash_profile

# Clone the repository
$ git clone https://github.com/medusa-project/book-tracker.git
$ cd book-tracker

# Install Ruby into RVM
# (Note: `.ruby-version` is used by RVM, but RVM isn't used in Docker, so the
# version it contains must be kept in sync with the one used in the Dockerfile.)
$ rvm install "$(< .ruby-version)" --autolibs=0

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

Navigate to `/signin` and log in as the user you created.

## Import books

```
$ bin/rails books:import
```

## Check services

```
$ bin/rails books:check_google
$ bin/rails books:check_hathitrust
$ bin/rails books:check_internet_archive
```

# Production

The task definition must contain the following environment variables:

* `SHIBBOLETH_HOST`
* `MASTER_KEY` (optional alternative to `config/master.key`)

`env.list` is not used in production. Instead, its variables are added to the
ECS task definition.

Then, build the container:

`./docker-build.sh`

Push the image to ECR:

`./ecr-push.sh`

Run it:

`./ecs-deploy.sh`


## Import books & check tasks

The buttons in the web interface at `/tasks` send requests to the ECS API
to start tasks (containers, more or less) that invoke these various commands
and then exit.












# Docker

## Locally

Fill in `env.list`. Then, build the container:

`./docker-build.sh`

And either run the server:

`./docker-run-server.sh`

Or a task (see `bin/rails -T` for a list):

`./docker-run-task.sh books:import`
