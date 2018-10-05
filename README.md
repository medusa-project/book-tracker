This is a basic getting-started guide for developers.

# Quick Links

* [JIRA board](https://bugs.library.illinois.edu/projects/MBT)

# Dependencies

* PostgreSQL 9.x

# Installation

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

Open `config/book_tracker.yml` and `config/database.yml` and add the environment
variables referenced within to your environment.

## 7) Create and seed the database

`$ bin/rails db:setup`

# Upgrading

## Migrating the database schema

`bin/rails db:migrate`

# Usage

## Importing books

Use the web interface at `/tasks`, or, from the command line:

`$ bin/rails books:import`

## Checking services

Use the web interface at `/tasks`, or, from the command line:

```
$ bin/rails books:check_google
$ bin/rails books:check_hathitrust
$ bin/rails books:check_internet_archive
```

# Notes

## Using Shibboleth locally

Log in as:
* `admin`/`admin@example.org` for admin privileges
* `user`/`user@example.org` for normal-user privileges
