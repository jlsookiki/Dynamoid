require 'spec_helper'
require 'dynamoid/adapter/table_definition'

describe Dynamoid::Adapter::TableDefinition do

  let(:table_name) { "a_table_name" }
  let(:capacity)   { 99 }
  let(:options) do
    {
      hash_key:  { my_hash_key:  :string },
      range_key: { my_range_key: :number },
      read_capacity:  capacity,
      write_capacity: capacity
    }
  end

  let(:definition) { described_class.new(table_name, options) }

  describe "#to_h" do

    let(:expected_attribute_definitions) do
      [
        {
          attribute_name: 'my_hash_key',
          attribute_type: 'S'
        },
        {
          attribute_name: 'my_range_key',
          attribute_type: 'N'
        }
      ]
    end

    let(:expected_key_schema) do
      [
        {
          attribute_name: 'my_hash_key',
          key_type:       'HASH'
        },
        {
          attribute_name: 'my_range_key',
          key_type:       'RANGE'
        }
      ]
    end

    subject { definition.to_h }

    it "includes the table name" do
      expect(subject[:table_name]).to eq(table_name)
    end

    it "includes the write capacity units" do
      expect(subject[:provisioned_throughput][:write_capacity_units]).to eq(capacity)
    end

    it "includes the read capacity units" do
      expect(subject[:provisioned_throughput][:read_capacity_units]).to eq(capacity)
    end

    it "includes the attribute definitions" do
      expect(subject[:attribute_definitions]).to eq(expected_attribute_definitions)
    end

    it "includes the key schema" do
      expect(subject[:key_schema]).to eq(expected_key_schema)
    end

  end

end
