require 'mustache'
require 'parse-cron'

module Watchy

  #
  # Defines the base class for user-defined reports
  #
  class Report < Mustache

    #
    # The settings defined globally
    #
    attr_accessor :config

    #
    # Initializes a report
    #
    # @param cron_def [String] The crontab style definition of the run
    #   times for this report
    #
    def initialize(cron_def = nil)
      @cron_def = cron_def
      @next_run = cron_parser && cron_parser.next(Time.now)
    end

    #
    # Generates the report
    # 
    # @return [String] The generated report
    #
    def generate
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
      render(template)
    end

    #
    # Indicates whether this report is currently due
    #
    # @return [Boolean] Whether this report should be run
    #
    def due?
      cron_parser && (@next_run < Time.now)
    end

    #
    # The database connection against which the report should run
    #
    def db
      config && 
        config[:database] && 
        config[:database][:connection]
    end

    #
    # Returns the +CronParser+ instance responsible for scheduling this report
    #
    # @return [CronParser] The configured cron definition
    #
    def cron_parser
      @cron_parser ||= (@cron_def && CronParser.new(@cron_def))
    end
    
    #
    # Pushes a report on the reporting queue
    #
    def broadcast!
      config[:broadcast_queue].push(generate)
    end

  end
end
