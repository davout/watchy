require 'mysql2'

require 'watchy/version'
require 'watchy/default_config'
require 'watchy/auditor'

module Watchy

  def self.boot!(config)
    Watchy::Auditor.new.run!
  end

  def self.connection
    @connection ||= connect_db(Settings[:db_server])
  end

  def self.connect_db(db)
    params =  { host: db[:host], username: db[:username], password: db[:password], encoding: db[:encoding] }
    logger.info "Connecting to #{db[:username]}@#{db[:host]}:#{db[:port]}..."
    Mysql2::Client.new(params)
  end

  def self.logger
    @logger ||= Settings[:logger]
  end

end

