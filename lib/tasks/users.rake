namespace :users do

  desc 'Create a user'
  task :create, [:username] => :environment do |task, args|
    User.create!(username: args[:name])
  end

end
