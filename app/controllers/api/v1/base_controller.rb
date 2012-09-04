class Api::V1::BaseController < ApplicationController
  # Disable CSRF protection as our API users don't have those tokens available.
  skip_before_filter :verify_authenticity_token

  # Error handlers are executed in LIFO ordering, so the least specific
  # exceptions should be specified first.
  #
  # These errors should be handled differently if we are in public or in
  # development.
  if Rails.application.config.consider_all_requests_local
    rescue_from Exception, :with => :debug
  else
    rescue_from Exception, :with => :internal_error
  end

  # These errors should always be handled in the same way
  rescue_from Errors::App, :with => :bad_request
  rescue_from Errors::NotFound, ActiveRecord::RecordNotFound, :with => :not_found
  rescue_from Errors::Authentication, Errors::Authorization, :with => :forbidden
  rescue_from ActiveRecord::RecordInvalid, :with => :invalid_record

protected
  # Protected: Tries to do a translation of params to our model objects based
  # on eid. Values will be available as instance variables corresponding to the
  # params key. i.e. @user
  #
  # TODO: Refactor this out.
  #
  # modifier - :any to require that at least one of the objects is in params
  #            or :all for all params
  # objects  - list of symbols or a Hash of symbols => :symbol
  # opts     - options.
  #            :params - overrides request params; use for tests.
  #            :controlller - overrides controller; use for tests.
  #
  # For now, it will require at least one of the specified objects to exist in
  # params.
  #
  # Examples
  #   expects :any, [:project, :organization]  # will use the corresponding class name
  #   expects :all, [:project, :organization]  #
  #   expects :all, :id => :user               # will look for a User with an id of params[:id]
  def expects(modifier, objects, opts=nil)
    controller = opts && opts[:controller] || self
    args = opts && opts[:params] || params

    if objects.is_a? Array
      objects = Hash[objects.map {|sym| [sym, sym] }]
    end

    found = objects.map do |k, v|
      #default to assume :key => Class
      name = k
      klass = v
      if v.is_a? Symbol #else, infer class name from symbol
        name = v
        klass = v.to_s.camelize.constantize
      end

      value = klass.send(:find_by_eid, args[k].to_s)
      controller.instance_variable_set("@#{name}".to_sym, value)
      [name, value]
    end

    found = Hash[found]

    case modifier
    when :any
      valid = found.values.compact.any?
      raise Errors::NotFound.new("Missing: #{found.keys.join(' or ')}") unless valid
    when :all
      valid = found.values.compact.size == found.values.size
      raise Errors::NotFound.new("Missing: #{found.keys.reject { |k| found[k] }.join(' and ')}") unless valid
    end
  end

  # Protected: Handle the render ourselves. This allows us to render straight
  # up json and even errors with the default behavior being rendering a rabl
  # template. This also will allow us to inject other things into the response
  # like debug information, etc.
  #
  # TODO: Refactor this back to using the standard render method.
  #
  # Example:
  #   render :json => {:mykey => 'val'}
  #   render :template => 'my/rabl/template'
  #   render :errors => [ {:message => 'OMG ERROR!', :field => 'kittens'} ], :status => 400
  def render(*args, &block)
    raise ::AbstractController::DoubleRenderError if response_body

    options = _normalize_render(*args, &block)

    json = if options[:errors]
      {:errors => options[:errors]}
    else
      {:results => (options[:json] || view_renderer.render(view_context, options))}
    end

    json[:debug] = options[:debug] if options[:debug]

    self.status = options[:status] if options[:status]
    self.content_type = Mime[:json]
    self.response_body = JSON.generate(json)
  end

  # Protected: Handles not found errors (404 errors)
  def not_found(exception)
    errors = [:message => exception.message]
    render :errors => errors, :status => 404
  end

  # Protected: Handles forbidden errors (403 errors)
  def forbidden(exception)
    errors = [:message => exception.message]
    render :errors => errors, :status => 403
  end

  # Protected: Handles request errors (400 errors)
  def bad_request(exception)
    errors = [:message => exception.message, :field => exception.field]
    render :errors => errors, :status => 400
  end

  # Protected: Handles invalid parameters (400 errors)
  #
  # In general if you can return an invalid_record rather than a bad_request
  # that's better.
  def invalid_record(exception)
    errors = []
    exception.record.errors.messages.each do |field, messages|
      errors.push(*messages.map{|m| {:field => field, :message => m}})
    end
    render :errors => errors, :status => 400
  end

  # Protected: A generic 500 error handler.
  #
  # It purposefully doesn't expose any data because it can be a security risk
  # to do so.
  def internal_error(exception)
    errors = [:message => "Internal Server Error"]
    render :errors => errors, :status => 500
  end

  # Protected: Displays as much debugging information as possible, useful for
  # debugging in development.
  #
  # This will only be shown in development.
  def debug(exception)
    file, line = 'Unknown', 0
    file, line, method = exception.backtrace[0].split(':') if exception.backtrace.any?
    debug = {
        :message => exception.inspect,
        :file => file,
        :line => line.to_i,
        :exception_type => exception.class.to_s,
        :trace => exception.backtrace
    }
    render :errors => [{ :message => "Internal Server Error" }], :debug => debug , :status => 500
  end
end
