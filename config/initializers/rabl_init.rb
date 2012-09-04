Rabl.configure do |config|
  # Commented as these are the defaults
  # config.json_engine = nil # Any multi\_json engines
  config.include_json_root = false
  # config.include_xml_root  = false
  # config.enable_json_callbacks = false
  # config.xml_options = { :dasherize  => true, :skip_types => false }
  config.escape_all_output = true
end

module Rabl
  class Engine
    # We do not care about their to_json. We will convert the hash to json ourself.
    # This gives us way more control over what actually is sent back to the client.
    def to_json(options={})
      to_hash(options)
    end
  end
end
