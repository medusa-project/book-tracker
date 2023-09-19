# Sets the Base Image w/slim tag for optimization
FROM ruby:3.0.3-slim 

# Env variables set to test env
ENV RAILS_ENV=test
ENV RAILS_LOG_TO_STDOUT=true 
ENV RAILS_MAX_THREADS=5
ENV RAILS_SERVE_STATIC_FILES=true 

# Install dependencies
# Ensures the package lists inside the image are up to date
# and the -y flag is a 'yes' to any prompts to install packages
# Here I included curl for purposes of health checks
# I did not include libpq-dev because a separate container will connect to postgres db
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

CMD ["bin/rails", "test"]