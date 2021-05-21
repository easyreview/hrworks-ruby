# frozen_string_literal: true

require_relative "hrworks/version"

module Hrworks
  class Error < StandardError; end
end

require_relative "hrworks/client"
require_relative "hrworks/request"
require_relative "hrworks/request/get_persons"
