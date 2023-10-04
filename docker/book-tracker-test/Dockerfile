# Sets the Base Image w/slim tag for optimization
FROM ruby:3.2.2-slim

# Env variables set to test env
ENV RAILS_ENV=test
ENV RAILS_LOG_TO_STDOUT=true 
ENV RAILS_MAX_THREADS=5
ENV RAILS_SERVE_STATIC_FILES=true 

# Install dependencies
# Ensures the package lists inside the image are up to date
RUN apt-get update && apt-get install -y \
  build-essential \
  curl \
  git \
  libpq-dev 

# Sets the working directory
RUN mkdir app 
WORKDIR /app

# Copy the Gemfile and Gemfile.lock and install gems
# set the config without development, but does include test
# kept default jobs 20 and retry 5 for background tasks
COPY Gemfile Gemfile.lock ./
RUN gem install bundler \ 
    && bundle config set without 'development' \
    && bundle install 

# Copy the main application except what's in dockerignore.
COPY . ./

RUN cp config/credentials/ci.yml config/credentials/test.yml 

CMD ["bin/rails", "test"]
