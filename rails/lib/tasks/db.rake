namespace :db do
  desc "Checks to see if the database exists"
  task :exists do
    begin
      Rake::Task['environment'].invoke
      con = ActiveRecord::Base.connection # make a connection to the database
    rescue => e
      puts e.message
      exit 1
    else
      puts "#{con.current_database} exists"
      exit 0
    end
  end
  task :alter_owner do
    begin
      Rake::Task['environment'].invoke
      user = ENV["DATABASE_OWNER"] || Rails.configuration.database_configuration[Rails.env]["username"]
      database = Rails.configuration.database_configuration[Rails.env]["database"]
      sql = %{ALTER DATABASE "#{database}" OWNER TO "#{user}"}
      puts sql
      ActiveRecord::Base.connection.execute(sql)
    rescue => e
      puts e.message
      exit 1
    end
  end
  task :add_extensions do
    Rake::Task["environment"].invoke
    if Rake::Task.task_defined?("db:psql:add_extensions")
      Rake::Task["db:psql:add_extensions"].invoke
    end
  end
end
