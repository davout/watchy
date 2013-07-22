require_relative '../../spec_helper'

describe Watchy::Config::DSL do
  describe '.get_from' do
    it 'should read the configuration from a block' do

Mysql2::Client.should_receive(:new).and_return(:db_conn)

      h = Watchy::Config::DSL.get_from do 

        sleep_for 42

        database do
          username 'albert'
          password 'einstein'
          hostname 'los-alamos'
          port 42
          schema 'relativity'
          audit_schema 'relativity-audit'

          drop_audit_schema!
        end

        logging do
          logger :foo
          level :batshit
        end

        audit do
          table :foo
          table :bar do
            field :baz do
            end

            disable_versioning!
          end
        end

        gpg do
          sign_with 'foo'
          encrypt_to 'bar'
        end

      end

      gpg = h.delete(:gpg)
      gpg.should be_an_instance_of Watchy::GPG

      h[:database].delete(:connection).should eql(:db_conn)

      h.should eql({

        sleep_for: 42,

        database: {
          username: 'albert',
          password: 'einstein',
          host: 'los-alamos',
          port: 42,
          schema: 'relativity',
          audit_schema: 'relativity-audit',
          drop_audit_schema: true
        },

        logging: {
          logger: :foo,
          level: :batshit
        },

        audit: {
          tables: {
            foo: {
              rules: {
                update: [],
                insert: []
              },
              versioning_enabled: true
            },
            bar: {
              fields: {
                baz: {
                  rules: {
                    insert: [],
                    update: []
                  }
                }
              },
              rules: {
                insert: [],
                update: []
              },
              versioning_enabled: false
            }
          }
        },

      })

    end
  end
end
