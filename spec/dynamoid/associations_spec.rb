require 'spec_helper'

describe "Dynamoid::Associations", skip: true do

  before do
    @magazine = Magazine.create
  end

  it 'defines a getter' do
    @magazine.should respond_to :subscriptions
  end

  it 'defines a setter' do
    @magazine.should respond_to :subscriptions=
  end
end
