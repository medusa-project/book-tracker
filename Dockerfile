# N.B.: this must match the Ruby version in the Gemfile, and /.ruby-version.
FROM ruby:3.0.3-slim

ENV RAILS_ENV=production
ENV RAILS_LOG_TO_STDOUT=true
ENV RAILS_SERVE_STATIC_FILES=true

RUN apt-get update && apt-get install -y \
  build-essential \
  git \
  libpq-dev

RUN mkdir app
WORKDIR /app

# Copy the Gemfile as well as the Gemfile.lock and install gems.
# This is a separate step so the dependencies will be cached.
COPY Gemfile Gemfile.lock ./
RUN gem install bundler \
    && bundle config set --local without 'development test' \
    && bundle install --jobs 20 --retry 5

# Copy the main application, except whatever is listed in .dockerignore.
COPY . ./

RUN bin/rails assets:precompile

EXPOSE 3000

# This is the web server entry point. It will need to be overridden when
# running the workers.
# TODO: invoke db:prepare here too. This will be problematic, though, if the DB migration would take longer than the ECS health check interval
CMD ["bin/rails", "server", "-b", "0.0.0.0"]
