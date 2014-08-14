require 'mustache'

require 'watchy/database_helper'
require 'watchy/queues_helper'
require 'watchy/periodic_task'

module Watchy

  #
  # Defines the base class for user-defined reports
  #
  class Report < PeriodicTask

    include Watchy::DatabaseHelper
    include Watchy::LoggerHelper
    include Watchy::QueuesHelper

    #
    # Initializes a report
    #
    # @param cron_def [String] The crontab style definition of the run
    #   times for this report
    #
    def initialize(cron_def = nil)
      super(cron_def) { }
    end

    #
    # Generates the report
    # 
    # @return [String] The generated report
    #
    def generate
      logger.info("Running report #{self.class.to_s}")
      report = do_render
      @next_run = cron_parser && cron_parser.next(Time.now)
      report
    end

    # 
    # Renders the template using the +template+ instance method
    #   which should return the path to the template
    #
    # @return [String] The generated report
    #
    def do_render
      Mustache.render(template, self)
    end
   
    #
    # Override the run method to broadcast the report
    #
    def run!
      broadcast!
      super
    end

    #
    # Pushes a report on the reporting queue
    #
    def broadcast!
      broadcast_queue.push(generate)
    end

    #
    # Returns the auditor identification string
    #
    # @return [String] The auditor identification string
    #
    def auditor_id
      Settings[:auditor_id]
    end

  end
end
