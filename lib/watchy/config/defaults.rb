require 'configliere'
require 'logger'

Settings({
  logging: {
    logger: Logger.new(STDOUT),
    level: :info
  },

  sleep_for: 1
})
