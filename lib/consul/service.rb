module Consul
  class Service
    require 'net/http'

    TIMEOUT = 0.5

    def initialize(base_path)
      @base_path = base_path.ends_with?("/") ? base_path : "#{base_path}/"
    end
    
    attr_reader :base_path
    
    def flatten_params(params)
      fp = {}
      params.each do |k,v|
        if v.is_a?(Hash)
          fv = flatten_params(v)
          fv.each do |fvk, fvv|
            fvk = fvk.to_s
            new_key = "#{k}[#{fvk.split("[")[0]}][#{fvk.split("[")[1..-1].join("[")}".chomp("[")
            fp[new_key] = fvv
          end
        else
          fp[k] = v
        end
      end
      return fp
    end

    def get(api_url, params = {}, headers = {}, timeout = TIMEOUT)
      http_call("Get", api_url, params, headers, timeout)
    end
    
    def post(api_url, params = {}, headers = {}, timeout = TIMEOUT)
      http_call("Post", api_url, params, headers, timeout)
    end

    def put(api_url, params = {}, headers = {}, timeout = TIMEOUT)
      http_call("Put", api_url, params, headers, timeout)
    end

    def patch(api_url, params = {}, headers = {}, timeout = TIMEOUT)
      http_call("Patch", api_url, params, headers, timeout)
    end
    
    def delete(api_url, params = {}, headers = {}, timeout = TIMEOUT)
      http_call("Delete", api_url, params, headers, timeout)
    end

    def http_call(method, api_url, params = {}, headers = {}, timeout = TIMEOUT)
      method.capitalize!
      api_url = api_url[1..-1] if api_url.starts_with?("/")
      raise "Unsupported method for http call" unless ["Get","Post","Put","Patch","Delete"].include?(method)
      uri = URI("#{@base_path}#{api_url}")
      http = Net::HTTP.new(uri.host,uri.port)
      if uri.scheme == "https"
        http.use_ssl=true
        http.verify_mode = OpenSSL::SSL::VERIFY_NONE
      end
      http.read_timeout = timeout
      request = "Net::HTTP::#{method}".constantize.new uri
      request.set_form_data(flatten_params(params))
      headers.each do |k,v|
        request[k.to_s] = v
      end
      http.request request
    end

    def to_s
      @base_path
    end
  end
end
