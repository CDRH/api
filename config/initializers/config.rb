CONFIG = YAML.load_file("#{Rails.root}/config/config.yml")[Rails.env]

VERSION = CONFIG["version"]

ES_URI = "#{CONFIG['es_path']}/#{CONFIG['es_index']}"

# Set default values for number of results per page
# and starting position
START = CONFIG["start"]
NUM = CONFIG["num"]
HL_NUM = CONFIG["hl_num"]
HL_CHARS = CONFIG["hl_chars"]

# TODO
# FIELDS = curl ES_URI/_mapping
