require "consul/service"
module Consul
  module DataLoader
    extend self

    attr_accessor :type

    def load
      Consul.append_methods(services_hash_to_struct, "services")
      Consul.append_methods(config_hash_to_struct, "config")
    end  
    
    def api_url
      Consul.api_url(@type)
    end

    def required_services
      Consul.required_services
    end

    def data_json
      require "open-uri"
      begin
        URI(api_url).read
      rescue => e
        Rails.loger.error("Failed to fetch data from consul")
        raise "Unable to fetch data from consul"
      end
    end

    def encoded_data
      begin 
        JSON.parse(data_json)
      rescue => e
        Rails.logger.error("Failed to parse json data recieved from consul api")
        raise "Unable to parse consul api data"
      end
    end

    def data
      begin 
        encoded_data.each{|i| i["Value"] = Base64.decode64(i["Value"]) if i["Value"] }
      rescue => e
        Rails.logger.error("Failed to decode data")
        raise "Unable to decode data"
      end
    end

    def sanitize_keys
      if keys.any? {|key| key.include?(".")}
        raise "Keys cannot have \".\""
      end
    end

    def keys
      data.collect{|i| i["Key"]}
    end

    def kv_hash
      sanitize_keys
      h = {}
      data.each do |i|
        key = i["Key"].gsub("#{Consul.root_folder(@type)}/","").gsub("/",".")
        value = i["Value"]
        value = value.to_s.starts_with?("http") ? Consul::Service.new(value) : value
        h[key] = value if value
      end
      return h
    end

    def validate_services_hash(h)
      missing_services = required_services - h.keys
      raise "All required services not found in Consul.\nMissing Services:\n#{missing_services.join("\n")}" unless (missing_services == [])
      unconfigured_urls = []
      required_services.each do |s|
        ([:public_url, :private_url] - h[s].keys.map(&:to_sym)).each do |url|
          unconfigured_urls.push("#{s}::#{url}")
        end
      end
      raise "All required Urls not configured.\nMissing URLs:\n#{unconfigured_urls.join("\n")}" unless unconfigured_urls == []
    end

    def nested_hash
      h = {}
      kv_hash.each do |key,value|
        node = h
        key.split(".")[0..-2].each do |k|
          node[k] = {} if node[k].nil?
          node = node[k]
        end
        node[key.split(".")[-1]] = value
      end
      validate_services_hash(h) if @type == "services"
      return h
    end
  
    def hash_to_struct(nested_hash)
      nested_hash.each do |key,value|
        nested_hash[key] = hash_to_struct(value) if value.is_a?(Hash)
        nested_hash[key] = (JSON.parse(value) rescue value) if value.is_a?(String)
      end
      OpenStruct.new(nested_hash) 
    end  
    
    def config_hash_to_struct
      @type = "config"
      hash_to_struct(nested_hash)
    end
    
    def services_hash_to_struct
      @type = "services"
      hash_to_struct(nested_hash)
    end

  end
end
