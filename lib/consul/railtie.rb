module Consul
  class Railtie < Rails::Railtie
    initializer "consul.service_loader" do |app|
      require "#{Rails.root}/config/initializers/consul.rb"
      Consul.load
    end 
  end
end
