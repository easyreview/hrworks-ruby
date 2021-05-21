# frozen_string_literal: true

require "digest"
require "openssl"
require "json"
require "cgi"
require "time"

module Hrworks
  # (Abstract) Base class for all specific requests to issue against the HRworks API.
  # Each "endpoint" of the API has (or should have) it's own request class, that inherits
  # from this base class.
  class Request
    CANONICAL_QUERY_STRING = ""
    CANONICAL_URL = "/"

    CONTENT_TYPE = "application/json; charset=utf-8"

    HEADER_AUTHORIZATION = "Authorization"
    HEADER_CONTENT_TYPE = "content-type"
    HEADER_DATE = "date"
    HEADER_HOST = "host"
    HEADER_HRWORKS_DATE = "x-hrworks-date"
    HEADER_HRWORKS_TARGET = "x-hrworks-target"

    HTTP_METHOD = "POST"

    SIGNATURE_ALGORITHM_IDENTIFIER = "HRWORKS-HMAC-SHA256"
    SIGNATURE_CLOSING_STRING = "hrworks_api_request"

    attr_reader :data

    def prepare_for_sending!(client:)
      @client = client
    end

    def headers
      {
        HEADER_HOST => @client.uri.host,
        HEADER_CONTENT_TYPE => CONTENT_TYPE,
        HEADER_DATE => http_timestamp,
        HEADER_HRWORKS_DATE => formatted_timestamp,
        HEADER_HRWORKS_TARGET => self.class::TARGET
      }
    end

    def signed_headers
      headers.merge(
        HEADER_AUTHORIZATION => authorization_header_value
      )
    end

    def body
      JSON.dump(data)
    end

    protected

    def sorted_header_keys
      @sorted_header_keys ||= [
        HEADER_CONTENT_TYPE,
        HEADER_HOST,
        HEADER_HRWORKS_DATE,
        HEADER_HRWORKS_TARGET
      ].map(&:downcase).sort
    end

    def canonical_headers
      @canonical_headers ||= sorted_header_keys.map do |header_key|
        header_value = headers[header_key]
        "#{header_key}:#{trim_whitespace(header_value)}"
      end.join("\n")
    end

    def signature
      result = @client.sign(formatted_timestamp.gsub(/T.*\z/, ""))
      result = @client.sign(@client.realm.to_s, secret: result)
      result = @client.sign(SIGNATURE_CLOSING_STRING, secret: result)

      @client.sign(string_to_sign, secret: result, hex: true)
    end

    def authorization_header_value
      "#{SIGNATURE_ALGORITHM_IDENTIFIER} "\
      "Credential=#{CGI.escape(@client.access_key)}/#{@client.realm}, "\
      "SignedHeaders=#{sorted_header_keys.join(";")}, "\
      "Signature=#{signature}"
    end

    def timestamp
      @timestamp ||= Time.now
    end

    def formatted_timestamp
      timestamp.utc.strftime("%Y%m%dT%H%M%SZ")
    end

    def http_timestamp
      timestamp.httpdate
    end

    def string_to_sign
      [
        SIGNATURE_ALGORITHM_IDENTIFIER,
        formatted_timestamp,
        Digest::SHA256.hexdigest(canonical_request)
      ].join("\n")
    end

    def canonical_request
      [
        HTTP_METHOD,
        CANONICAL_URL,
        CANONICAL_QUERY_STRING,
        *canonical_headers,
        nil,
        Digest::SHA256.hexdigest(body)
      ].join("\n")
    end

    def trim_whitespace(string)
      string.gsub(/[[:space:]]*\z/, "").gsub(/\A[[:space:]]*/, "")
    end
  end
end
