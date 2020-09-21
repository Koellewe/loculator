# Create a mysql client
def connect_db
  cfg = Rails.application.config.cfg
  Mysql2::Client.new(:host => 'localhost', :username => cfg['db_usr'],
                     :password => cfg['db_pwd'], :database => cfg['db_name'])
end
