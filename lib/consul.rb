require "consul/data_loader"
module Consul
  extend self
  
  def load
    DataLoader.load
  end
  
  attr_writer :server_host, :server_port, :config_root_folder, :required_services

  def root_folder=(value)
    value.is_a?(Hash) ? (@root_folder = value) : raise("Consul root folder expects a Hash")
  end

  def root_folder(type)
    @root_folder ||= {}
    @root_folder[type.to_s] || @root_folder[type.to_sym] || type.to_s
  end

  def required_services
    @required_services ||= []
  end
  
  def server_host
    @server_host ||= "localhost"
  end

  def server_port
    @server_port ||= "8500"
  end

  def api_url(type)
    "http://#{server_host}:#{server_port}/v1/kv/#{root_folder(type)}?recurse"
  end

  def append_methods nested_hash, method_name
    define_method :"#{method_name}" do
      OpenStruct.new(nested_hash)
    end
  end
  
  def subkeys key
    key_array = key.split(".")
    key_array.each_with_index.map{|k,index| key_array[0..index].join(".")}
  end

end

require 'consul/railtie' if defined?(Rails)
