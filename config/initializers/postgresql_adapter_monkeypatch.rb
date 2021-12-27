# frozen_string_literal: true

require 'active_record/connection_adapters/postgresql_adapter'

module ActiveRecord
  module ConnectionAdapters
    class PostgreSQLAdapter
      def set_standard_conforming_strings
        old = client_min_messages
        self.client_min_messages = 'warning'
        begin
          execute('SET standard_conforming_strings = on', 'SCHEMA')
        rescue StandardError
          nil
        end
      ensure
        self.client_min_messages = old
      end
    end
  end
end
