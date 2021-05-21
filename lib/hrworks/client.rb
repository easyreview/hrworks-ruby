# frozen_string_literal: true

require "uri"
require "net/https"
require "openssl"

module Hrworks
  # Used to issue requests against the HRworks API
  class Client
    # Error when request to HRWorks failed (based on their response)
    class ResponseError < ::Hrworks::Error
      attr_reader :response

      def initialzize(response)
        @response = response
      end

      def message
        "Invalid Response: #{response.code} - #{response.body}"
      end
    end

    URIS = {
      production: URI("https://api.hrworks.de"),
      demo: URI("https://api-demo.hrworks.de")
    }.freeze

    DEBUG_MODE = false

    DIGEST_TYPE = "SHA256"

    DIGEST_METHOD_BINARY = OpenSSL::HMAC.method(:digest)
    DIGEST_METHOD_HEX = OpenSSL::HMAC.method(:hexdigest)

    STATUS_CODE_SUCCESS = "200"
    STATUS_CODE_CREATED = "201"

    attr_reader :realm, :access_key

    def initialize(access_key:, secret_key:, realm: :production)
      @access_key = access_key
      @secret_key = secret_key
      @realm = realm.to_sym
    end

    def send(api_request)
      api_request.prepare_for_sending!(client: self)

      http_request = build_http_request(api_request: api_request)

      response = http_client.request(http_request)

      parsed_response(response)
    end

    def sign(string, secret: nil, hex: false)
      secret ||= "HRWORKS#{@secret_key}"
      method = hex ? DIGEST_METHOD_HEX : DIGEST_METHOD_BINARY
      method.call(DIGEST_TYPE, secret, string)
    end

    def uri
      URIS[realm]
    end

    protected

    def http_client
      return @http_client if @http_client

      http = Net::HTTP.new(uri.host, uri.port)
      http.set_debug_output($stdout) if DEBUG_MODE
      http.use_ssl = (uri.scheme == "https")

      @http_client = http
    end

    def parsed_response(raw_response)
      case raw_response.code
      when STATUS_CODE_SUCCESS, STATUS_CODE_CREATED
        JSON.parse(response.body)
      else
        raise ResponseError, response
      end
    end

    def build_http_request(api_request:)
      http_request = Net::HTTP::Post.new(uri.request_uri)

      http_request.initialize_http_header({})
      api_request.signed_headers.each do |key, value|
        http_request[key] = value
      end
      http_request.body = api_request.body

      http_request
    end
  end
end
