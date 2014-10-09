Gem::Specification.new do |s|
  s.name        = 'consul.rails'
  s.version     = '0.0.1'
  s.date        = '2010-04-28'
  s.summary     = "Consul k/v as rails config" 
  s.description = "A wrapper over Consul key/value store for Rails Application Configuration management"
  s.authors     = ["Abhishek Anand"]
  s.email       = 'abhishek@housing.com'
  s.files       = Dir["{lib, bin}/**/*"]
  s.homepage    =
    'https://github.com/raianand/consul.rails'
  s.license       = 'MIT'
  s.executables = ["consul-load","consul-dump"]
end
