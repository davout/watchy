require 'configliere'
require 'logger'

require 'watchy/local_queue'

Settings({
  logging: {
    logger: Logger.new(STDOUT),
    level: :info
  },

  sleep_for: 1,

  queue: Watchy::LocalQueue.new
})
