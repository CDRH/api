CONFIG = YAML.load_file("#{Rails.root}/config/config.yml")[Rails.env]

VERSION = CONFIG["version"]

ES_URI = "#{CONFIG['es_path']}/#{CONFIG['es_index']}"

# Set default values for number of results per page
# and starting position
START = 0
NUM = 20

# TODO
# FIELDS = curl ES_URI/_mapping
