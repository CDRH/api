CONFIG = YAML.load_file("#{Rails.root}/config/config.yml")[Rails.env]

VERSION = CONFIG["version"]

ES_URI = "#{CONFIG['es_path']}/#{CONFIG['es_index']}"

# TODO
# FIELDS = curl ES_URI/_mapping
