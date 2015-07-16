module Dynamoid
  module Adapter

    class TableDefinition

      attr_reader :table_name, :options

      def initialize(table_name, options = {})
        @table_name = table_name
        @options    = options
      end

      def to_h
        {
          table_name:            @table_name,
          attribute_definitions: attribute_definitions,
          key_schema:            key_schema,
          provisioned_throughput: {
            read_capacity_units:  read_capacity,
            write_capacity_units: write_capacity,
          }
        }
      end

      private

      def key_schema
        elements_for :key_schema
      end

      def attribute_definitions
        elements_for :attribute_definitions
      end

      def elements_for(type)
        hash_key, range_key = @options.values_at(:hash_key, :range_key)

        schema = []

        if type == :key_schema
          schema << key_schema_element(hash_key,  :hash)
          schema << key_schema_element(range_key, :range) if range_key
        elsif type == :attribute_definitions
          schema << attribute_definitions_element(hash_key,  :hash)
          schema << attribute_definitions_element(range_key, :range) if range_key
        end

        schema
      end

      def key_schema_element(desc, key_type)
        name = desc.keys.first

        {
          attribute_name: name.to_s,
          key_type:       key_type.to_s.upcase
        }
      end

      def attribute_definitions_element(desc, key_type)
        (name, type) = desc.to_a.first

        unless [:string, :number, :binary].include?(type)
          msg = "Invalid #{key_type} key type, expected :string, :number or :binary."
          raise ArgumentError, msg
        end

        {
          attribute_name: name.to_s,
          attribute_type: type.to_s[0,1].upcase
        }
      end

      def read_capacity
        @options[:read_capacity]
      end

      def write_capacity
        @options[:write_capacity]
      end

    end

  end
end
