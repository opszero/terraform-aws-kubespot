require "yaml"
class App < Thor
  package_name "App"
  desc "config_yaml FILE", "generate a yaml config for a given environment"
  method_option :env, aliases: "-e", desc: "The environment that you care about"
  def config_yaml(file)
    if options[:env]
      puts YAML.dump(YAML.load(`cat #{file} | envsubst`.to_yaml)[options[:env]])
    else
      puts File.read(file)
    end
  end
end
