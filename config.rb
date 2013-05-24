require 'yaml'

module PQDownloader

  class Config
    CONFIG_FNAME = 'config.yml'
    CONFIG_FIELDS = %w( consumer_key consumer_secret callback_host callback_port )

    def initialize
      path = File.join(File.expand_path(File.dirname(__FILE__)), CONFIG_FNAME)
      @config = YAML::load(File.open path)

      CONFIG_FIELDS.each { |field|
        # Verify that each config field exists.
        raise "No #{field} defined in #{CONFIG_FNAME}" unless @config[field]

        # Define an accessor for each config field.
        self.class.class_eval {
          define_method(field) { @config[field] }
        }
      }
    end

  end

end
