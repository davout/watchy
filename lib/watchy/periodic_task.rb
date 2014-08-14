require 'parse-cron'

module Watchy

  #
  # Defines a periodic task to be performed at regular interval
  #
  class PeriodicTask

    include Watchy::LoggerHelper

    @@periodic_tasks = []

    def self.tasks
     @@periodic_tasks
    end

    def self.tasks=(t)
      @@periodic_tasks = t
    end

    #
    # Initializes a periodic task
    #
    def initialize(cron_def, &block)
      @cron_def = cron_def
      @block    = block
      @next_run = cron_parser && cron_parser.next(Time.now)
      PeriodicTask.tasks << self
    end

    #
    # Runs the periodic task
    #
    def run!
      logger.info("Running task #{self.class.to_s}")
      @block.call
      @next_run = cron_parser && cron_parser.next(Time.now)
    end

    #
    # Run all due periodic tasks
    #
    def self.run_all_due!
      tasks.select(&:due?).each(&:run!)
    end

    #
    # Indicates whether this task is currently due
    #
    # @return [Boolean] Whether this report should be run
    #
    def due?
      cron_parser && (@next_run < Time.now)
    end

    #
    # Returns the +CronParser+ instance responsible for scheduling this report
    #
    # @return [CronParser] The configured cron definition
    #
    def cron_parser
      @cron_parser ||= (@cron_def && CronParser.new(@cron_def))
    end
  end
end
