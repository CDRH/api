config = YAML.load_file("#{Rails.root}/config/config.yml")[Rails.env]

SETTINGS = {
  "version" => config["version"],
  "es_uri" => "#{config['es_path']}/#{config['es_index']}"
}

# add all of the settings from the config file to SETTINGS constant
config["settings"].each do |key, value|
  SETTINGS[key] = value
end

SETTINGS.freeze
