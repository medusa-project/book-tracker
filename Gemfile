source 'https://rubygems.org'
git_source(:github) { |repo| "https://github.com/#{repo}.git" }

ruby '3.0.3'

gem 'autoprefixer-rails'
gem 'aws-sdk-ecs', '~> 1' # used to invoke async tasks
gem 'aws-sdk-s3', '~> 1'  # used to access the bucket containing MARCXML records
gem 'csv_builder'
gem "font-awesome-sass", "~> 5.6" # Provides all of our icons
gem 'haml'
gem 'haml-rails'
gem 'jbuilder', '~> 2.5'
gem 'jquery-rails'
gem 'local_time'
gem 'mini_racer', platforms: :ruby
gem 'omniauth'
gem 'omniauth-shibboleth'
gem 'pg'
gem 'puma'
gem 'rails', '~> 6.0.4.1'
gem 'sassc'
gem 'scars-bootstrap-theme', github: 'medusa-project/scars-bootstrap-theme',
    branch: 'release/bootstrap-4.4'
gem 'uglifier', '>= 1.3.0'

group :development do
  gem 'listen'
end

group :production do
  gem "omniauth-rails_csrf_protection"
end
