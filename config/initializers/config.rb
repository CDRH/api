config_path = Rails.root.join("config", "config.yml")
config = YAML.load_file(config_path, aliases: true)[Rails.env]

ES_URI = "#{config['es_path']}/#{config['es_index']}"
METADATA = config["metadata"]
SETTINGS = config["settings"]
