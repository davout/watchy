require 'watchy/default_update_rule'

module Watchy

  #
  # This class represents a table column
  #
  class Field

    # 
    # The table this field belongs to
    #
    attr_accessor :table

    #
    # The field name
    #
    attr_accessor :name

    #
    # The field DB type
    #
    attr_accessor :type

    #
    # Whether this field allows NULLs
    #
    attr_accessor :nullable

    #
    # Whether this field is part of the primary key
    #
    attr_accessor :key

    #
    # The default value for this field
    #
    attr_accessor :default

    #
    # The extra attributes for this field
    #
    attr_accessor :extra

    #
    # Initializes a field given a table, a field name, its type, whether it is nullable,
    # whether it is part of the primary key, its default value and its extra attribues
    #
    def initialize(table, name, type, nullable = true, key = false, default = nil, extra = nil)
      @table    = table
      @name     = name
      @type     = type
      @nullable = nullable
      @key      = key
      @default  = default
      @extra    = extra
      @rules    = read_rules
    end

    #
    # The difference filter for this field
    #
    # @return [String] A +WHERE+ fragment matching when the field has a different value in the
    #   audit and watched databases
    #
    def difference_filter
      "((#{watched} IS NULL AND #{audit} IS NOT NULL) OR (#{watched} IS NOT NULL AND #{audit} IS NULL) OR (#{watched} <> #{audit}))"
    end


    #
    # Returns the fully qualified field name in the watched table
    #
    # @return [String] The fully qualified name of the field in the watched table
    #
    def watched
      "#{table.watched}.`#{name}`"
    end

    #
    # Returns the fully qualified field name in the audit table
    #
    # @return [String] The fully qualified name of the field in the audit table
    #
    def audit
      "#{table.audit}.`#{name}`"
    end

    #
    # Returns the rules applicable to the passed event (+:insert+ or +:update+)
    #
    # @param event [Symbol] The event : +:insert+ or +:update+
    # @return [Array<Watchy::Rule>] The rules to enforce
    #
    def rules(event)
      @rules[event]
    end

    #
    # Executes the rules defined for the UPDATE event
    #
    # @param watched_row [Hash] The row copy in the audited schema
    # @param audit_row [Hash] The row copy in the audit schema
    # @return [Array<String>] The error messages resulting from executing the defined rules, if any
    #
    def on_update(watched_row, audit_row)
      rules(:update).inject([]) do |violations, rule|
        v = rule.execute(watched_row, audit_row)

        if v
          violations << {
            rule_name: rule.name,
            description: v,
            item: [watched_row, audit_row]
          }
        end

        violations
      end.compact
    end

    #
    # Executes the rules defined for the INSERT event
    #
    # @param audit_row [Hash] The row copy in the audit schema
    # @return [Array<String>] The error messages resulting from executing the defined rules, if any
    #
    def on_insert(audit_row)
      rules(:insert).inject([]) do |violations, rule|
        v = rule.execute(audit_row)

        if v
          violations << {
            rule_name: rule.name,
            description: v,
            item: audit_row
          }
        end

        violations
      end.compact
    end

    #
    # Returns the rules for this field, or the defaults if no configuration was made
    #
    # @return [Hash] The hash of rules
    #
    def read_rules
      fields = table.auditor.config[:audit][:tables][table.name.to_sym][:fields]
      config = fields && fields[name.to_sym]
      config = config ? config[:rules] : { insert: [], update: [] }

      if config[:update].empty?  
        config[:update] << Watchy::DefaultUpdateRule.new(name)
      end

      config
    end
  end
end
