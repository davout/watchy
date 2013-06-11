require 'mysql2'

require 'watchy/version'
require 'watchy/default_config'
require 'watchy/auditor'

module Watchy

  def self.boot!
    Watchy::Auditor.new.run!
  end

  def self.connection
    @connection ||= connect_db(Settings[:db_server])
  end

  def self.connect_db(db)
    logger.info "Connecting to #{db[:username]}@#{db[:host]}:#{db[:port]}..."
    Mysql2::Client.new(db)
  end

  def self.logger
    unless @logger
      @logger = Settings[:logger] || Logger.new(STDOUT)
      @logger.level = eval("Logger::Severity::#{Settings[:loglevel].upcase}")
    end

    @logger
  end

end

