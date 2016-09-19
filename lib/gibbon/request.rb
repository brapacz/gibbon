module Gibbon
  class Request
    attr_accessor :api_key, :api_endpoint, :timeout, :proxy, :faraday_adapter, :debug, :logger

    DEFAULT_TIMEOUT = 30
    HTTP_METHODS_MAP = { retrieve: :get, upsert: :put, update: :patch, create: :post }.freeze

    def initialize(api_key: nil, api_endpoint: nil, timeout: nil, proxy: nil, faraday_adapter: nil, debug: false, logger: nil)
      @path_parts = []
      @api_key = api_key || self.class.api_key || ENV['MAILCHIMP_API_KEY']
      @api_key = @api_key.strip if @api_key
      @api_endpoint = api_endpoint || self.class.api_endpoint
      @timeout = timeout || self.class.timeout || DEFAULT_TIMEOUT
      @proxy = proxy || self.class.proxy || ENV['MAILCHIMP_PROXY']
      @faraday_adapter = faraday_adapter || Faraday.default_adapter
      @logger = logger || self.class.logger || ::Logger.new(STDOUT)
      @debug = debug
    end

    def method_missing(method, *args)
      # To support underscores, we replace them with hyphens when calling the API
      @path_parts << method.to_s.gsub("_", "-").downcase
      @path_parts << args if args.length > 0
      @path_parts.flatten!
      self
    end

    def send(*args)
      if args.length == 0
        method_missing(:send, args)
      else
        __send__(*args)
      end
    end

    def path
      @path_parts.join('/')
    end

    def create(params: nil, headers: nil, body: nil)
      APIRequest.new(builder: self).post(params: params, headers: headers, body: body)
    ensure
      reset
    end

    def update(params: nil, headers: nil, body: nil)
      APIRequest.new(builder: self).patch(params: params, headers: headers, body: body)
    ensure
      reset
    end

    def upsert(params: nil, headers: nil, body: nil)
      APIRequest.new(builder: self).put(params: params, headers: headers, body: body)
    ensure
      reset
    end

    def retrieve(params: nil, headers: nil)
      APIRequest.new(builder: self).get(params: params, headers: headers)
    ensure
      reset
    end

    def delete(params: nil, headers: nil)
      APIRequest.new(builder: self).delete(params: params, headers: headers)
    ensure
      reset
    end

    def to_batch(method, **attributes)
      method = HTTP_METHODS_MAP[method] if HTTP_METHODS_MAP.has_key?(method)
      APIRequest.new(builder: self).to_batch(method, **attributes)
    ensure
      reset
    end

    protected

    def reset
      @path_parts = []
    end

    class << self
      attr_accessor :api_key, :timeout, :api_endpoint, :proxy, :logger

      def method_missing(sym, *args, &block)
        new(api_key: self.api_key, api_endpoint: self.api_endpoint, timeout: self.timeout, proxy: self.proxy, logger: self.logger).send(sym, *args, &block)
      end
    end
  end
end
