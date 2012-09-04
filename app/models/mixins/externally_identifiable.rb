module Mixins
  # This module is responsible for generating an external identifier for any
  # ActiveRecord classes it's mixed into.
  #
  # Classes are expected to have a property called 'eid' to hold the identifier.
  module ExternallyIdentifiable
    def self.included(base)
      base.instance_eval <<-DONE
        before_create :generate_eid
      DONE
    end

  protected
    def generate_eid()
      self.eid = SecureRandom.hex(8)
    end
  end
end
