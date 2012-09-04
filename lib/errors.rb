module Errors
  class App < Exception
    attr_accessor :message, :field

    def initialize(message, field=nil)
      @message = message
      @field = field
    end
  end

  class NotFound < App
  end

  class Authentication < App
  end

  class Authorization < Authentication
  end
end
