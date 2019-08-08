namespace :deploytag do
  namespace :db do
    desc "Checks to see if the database exists"
    task :exists => :environment do
      begin
        con = ActiveRecord::Base.connection # make a connection to the database
      rescue => e
        puts e.message
        exit 1
      else
        puts "#{con.current_database} exists"
        exit 0
      end
    end
  end
end
