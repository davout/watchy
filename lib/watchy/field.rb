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
      "`#{table.watched}`.`#{name}`"
    end

    #
    # Returns the fully qualified field name in the audit table
    #
    # @return [String] The fully qualified name of the field in the audit table
    #
    def audit
      "`#{table.audit}`.`#{name}`"
    end
  end
end
