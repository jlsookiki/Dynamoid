require 'spec_helper'

describe "Dynamoid::Config" do

  before :each do
    Dynamoid::Config.reset_namespace
  end

  after :each do
    Dynamoid.config { |config| config.namespace = 'dynamoid_tests' }
  end

  it "returns a namespace for non-Rails apps" do
    expect(Dynamoid::Config.namespace).to eq('dynamoid')
  end

  it "returns a namespace for Rails apps" do
    class Rails; end
    allow(Rails).to receive(:application).and_return(double(class: double(parent_name: 'TestApp')))

    allow(Rails).to receive(:env).and_return('development')
    Dynamoid::Config.send(
      :option, :namespace,
      default: defined?(Rails) ? "dynamoid_#{Rails.application.class.parent_name}_#{Rails.env}" : "dynamoid"
    )

    expect(Dynamoid::Config.namespace).to eq("dynamoid_TestApp_development")
  end

end
