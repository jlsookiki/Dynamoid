require 'spec_helper'

describe Dynamoid::Adapter do

  def test_table; 'dynamoid_tests_TestTable'; end
  let(:single_id){'123'}
  let(:many_ids){%w(1 2)}

  before(:all) do
    described_class.create_table(test_table, :id) unless described_class.list_tables.include?(test_table)
  end

  it 'extends itself automatically' do
    lambda {described_class.list_tables}.should_not raise_error
  end

  it 'raises NoMethodError if we try a method that is not on the child' do
    lambda {described_class.foobar}.should raise_error(NoMethodError)
  end

  context 'without partioning' do
    before(:all) do
      @previous_value = Dynamoid::Config.partitioning
      Dynamoid::Config.partitioning = false
    end

    after(:all) do
      Dynamoid::Config.partitioning = @previous_value
    end

    it 'writes through the adapter' do
      expect(described_class).to receive(:put_item).with(test_table, {:id => single_id}, nil).and_return(true)
      described_class.write(test_table, {:id => single_id})
    end

    it 'reads through the adapter for one ID' do
      expect(described_class).to receive(:get_item).with(test_table, single_id, {}).and_return(true)
      described_class.read(test_table, single_id)
    end

    it 'reads through the adapter for many IDs' do
      expect(described_class).to receive(:batch_get_item).with({test_table => many_ids}, {}).and_return(true)
      described_class.read(test_table, many_ids)
    end

    it 'delete through the adapter for one ID' do
      expect(described_class).to receive(:delete_item).with(test_table, single_id, {}).and_return(nil)
      described_class.delete(test_table, single_id)
    end

    it 'deletes through the adapter for many IDs' do
      expect(described_class).to receive(:batch_delete_item).with({test_table => many_ids}).and_return(nil)
      described_class.delete(test_table, many_ids)
    end

    it 'reads through the adapter for one ID and a range key' do
      expect(described_class).to receive(:get_item).with(test_table, single_id, :range_key => 2.0).and_return(true)
      described_class.read(test_table, single_id, :range_key => 2.0)
    end

    it 'reads through the adapter for many IDs and a range key' do
      expect(described_class).to receive(:batch_get_item).with({test_table => [['1', 2.0], ['2', 2.0]]}, {}).and_return(true)
      described_class.read(test_table, many_ids, :range_key => 2.0)
    end

    it 'deletes through the adapter for one ID and a range key' do
      expect(described_class).to receive(:delete_item).with(test_table, single_id, :range_key => 2.0).and_return(nil)
      described_class.delete(test_table, single_id, :range_key => 2.0)
    end

    it 'deletes through the adapter for many IDs and a range key' do
      expect(described_class).to receive(:batch_delete_item).with({test_table => [['1', 2.0], ['2', 2.0]]}).and_return(nil)
      described_class.delete(test_table, many_ids, :range_key => [2.0,2.0])
    end
  end

  configured_with 'partitioning' do
    let(:partition_range){0...Dynamoid::Config.partition_size}

    it 'writes through the adapter', skip: true do
      Random.expects(:rand).with(Dynamoid::Config.partition_size).once.and_return(0)
      described_class.write(test_table, {:id => 'testid'})

      described_class.get_item(test_table, 'testid.0')[:id].should == 'testid.0'
      described_class.get_item(test_table, 'testid.0')[:updated_at].should_not be_nil
    end

    it 'reads through the adapter for one ID', skip: true do
      expect(described_class).to receive(:batch_get_item).with({test_table => partition_range.map{|n| "123.#{n}"}}, {}).and_return({})
      described_class.read(test_table, single_id)
    end

    it 'reads through the adapter for many IDs', skip: true do
      expect(described_class).to receive(:batch_get_item).with({test_table => partition_range.map{|n| "1.#{n}"} + partition_range.map{|n| "2.#{n}"}}, {}).and_return({})
      described_class.read(test_table, many_ids)
    end

    it 'reads through the adapter for one ID and a range key', skip: true do
      expect(described_class).to receive(:batch_get_item).with({test_table => partition_range.map{|n| ["123.#{n}", 2.0]}}, {}).and_return({})
      described_class.read(test_table, single_id, :range_key => 2.0)
    end

    it 'reads through the adapter for many IDs and a range key', skip: true do
      expect(described_class).to receive(:batch_get_item).with({test_table => partition_range.map{|n| ["1.#{n}", 2.0]} + partition_range.map{|n| ["2.#{n}", 2.0]}}, {}).and_return({})
      described_class.read(test_table, many_ids, :range_key => 2.0)
    end

    it 'returns an ID with all partitions' do
      described_class.id_with_partitions('1').should =~ partition_range.map{|n| "1.#{n}"}
    end

    it 'returns an ID and range key with all partitions' do
      described_class.id_with_partitions([['1', 1.0]]).should =~ partition_range.map{|n| ["1.#{n}", 1.0]}
    end

    it 'returns a result for one partitioned element', skip: true do
      @time = DateTime.now
      @array =[{:id => '1.0', :updated_at => @time - 6.hours},
               {:id => '1.1', :updated_at => @time - 3.hours},
               {:id => '1.2', :updated_at => @time - 1.hour},
               {:id => '1.3', :updated_at => @time - 6.hours},
               {:id => '2.0', :updated_at => @time}]

      described_class.result_for_partition(@array,test_table).should =~ [{:id => '1', :updated_at => @time - 1.hour},
                                                                         {:id => '2', :updated_at => @time}]
    end

    it 'returns a valid original id and partition number' do
      @id = "12345.387327.-sdf3"
      @partition_number = "4"
      described_class.get_original_id_and_partition("#{@id}.#{@partition_number}").should == [@id, @partition_number]
    end

    it 'delete through the adapter for one ID' do
      expect(described_class).to receive(:batch_delete_item).with(test_table => partition_range.map{|n| "123.#{n}"}).and_return(nil)
      described_class.delete(test_table, single_id)
    end

    it 'deletes through the adapter for many IDs' do
      expect(described_class).to receive(:batch_delete_item).with(test_table => partition_range.map{|n| "1.#{n}"} + partition_range.map{|n| "2.#{n}"}).and_return(nil)
      described_class.delete(test_table, many_ids)
    end

    it 'deletes through the adapter for one ID and a range key' do
      expect(described_class).to receive(:batch_delete_item).with(test_table => partition_range.map{|n| ["123.#{n}", 2.0]}).and_return(nil)
      described_class.delete(test_table, single_id, :range_key => 2.0)
    end

    it 'deletes through the adapter for many IDs and a range key' do
      expect(described_class).to receive(:batch_delete_item).with(test_table => partition_range.map{|n| ["1.#{n}", 2.0]} + partition_range.map{|n| ["2.#{n}", 2.0]}).and_return(nil)
      described_class.delete(test_table, many_ids, :range_key => [2.0,2.0])
    end
  end

end
