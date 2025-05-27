# N.B.: this must match the Ruby version in the Gemfile, and /.ruby-version.

# Set the Base Image
FROM ruby:3.2.2-slim

# Set Environment Variables
ENV RAILS_ENV=production
ENV DOCKER=true 
# Sends log output (log msgs/error msgs) to the standard output instead of saving to log files.
ENV RAILS_LOG_TO_STDOUT=true
# The app's web server is configured to serve static files (CSS, JS, etc) directly to client instead of serving from the app server.
ENV RAILS_SERVE_STATIC_FILES=true
ENV CHROME_BIN=/usr/bin/chromium
ENV CHROMEDRIVER_BIN=/usr/bin/chromedriver

# Install Dependencies
# Ensures package lists inside the Docker image are up to date
# the -y flag is a 'yes' to any prompts to install packages
RUN apt-get update && apt-get install -y \
  build-essential \
  git \
  libpq-dev

# Install Chromium and ChromeDriver 
RUN apt-get update && apt-get install -y \
  chromium \
  chromium-driver \
  fonts-liberation \
  libappindicator3-1 \
  libasound2 \
  libatk-bridge2.0-0 \
  libatk1.0-0 \
  libcups2 \
  libdbus-glib-1-2 \
  libgbm-dev \
  libgtk-3-0 \
  libnspr4 \
  libnss3 \
  libx11-xcb1 \
  libxcomposite1 \
  libxcursor1 \
  libxdamage1 \
  libxext6 \
  libxfixes3 \
  libxi6 \
  libxrandr2 \
  xdg-utils  \
  && apt-get clean \
  && rm -rf /var/lib/apt/lists/*

# Set Working Directory
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

#Expose the Ports
EXPOSE 3000

# This is the web server entry point. It will need to be overridden when
# running the workers.
# TODO: invoke db:prepare here too. This will be problematic, though, if the DB migration would take longer than the ECS health check interval
# Start the Application
CMD ["bin/rails", "server", "-b", "0.0.0.0"]
