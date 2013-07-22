# Watchy, audit and monitoring framework

## Usage

After installing the gem you must configure the framework and tell it what it should monitor and how it should audit it.

**Example :**

````ruby
require 'watchy'

Watchy.configure do
  # How long to sleep between each audit loop, defaults to 1s (optional)
  sleep_for 2

  # Configure the way events are logged (optional)
  logging do
    level  :warn
    logger Logger.new(STDOUT)
  end
  
  # Configure the database to watch, the audit database (mandatory)
  database do
    username      'rails'
    password      'rails'
    hostname      'localhost'
    port          3306
        
    # The database that should be monitored
    schema        'bitcoin-platform_dev'
    
    # The database that watchy will use to store its copy of the audited data
    audit_schema  'bpp-audit'

 # Whether to restart each run with an empty audit DB
    drop_audit_schema!
  end

  # The GPG configuration
  gpg do
    # The GPG key ID to use for signing
    sign_with  'david@bitcoin-central.net'
    
    # The GPG key IDs to which data should be encrypted
    encrypt_to 'backups@paymium.com'
    encrypt_to 'david@bitcoin-central.net'
  end

  # The auditing configuration
  audit do
  
    # A table name by itself to get the default configuration :
    # inserts allowed, no updates, no deletes.
    table :account_operations


    # It is possible to specify custom rules on the update, insert
    # and delete events. 
    table :accounts do
    
      # To define a rule use the `on_insert` and `on_update` methods.
      on_insert :yoodelooz do |row|
        "An account name can't be YOODELA" if row['name'] == 'YOODELA'
      end

      # Rules defined on insert events get passed the audit copy of the row,
      # while rules on the update event get passed both the watched and audit copies
      on_update do |original_row, updated_row|
        "Updated at went backwards" if original_row['updated_at'] > updated_row['updated_at']
      end

      on_update :some_rule_name do |original_row, updated_row|
        "Sign in count went backwards" if original_row["sign_in_count"] > updated_row["sign_in_count"]
      end     

      # Rules can also be defined on specific fields
      field :name do
        on_insert :check_name_format do |row|
          "Whoops, the format seems incorrectly formatted" unless row['name'] =~ /.*/
        end
      end
    end
  end
end

Watchy.boot!
````

## Reporting

Watchy can be configured to generate and publish signed reports on the audited data.

## TODO

 * DELETEs
 * Reporting

## Requirements

 * Currently Watchy supports only MySQL databases.
 * The audit database will always be created on the same server as the audited data, it is therefore desirable that updates happen through a one-way mechanism, MySQL database replication being perfectly suited for this purpose.
