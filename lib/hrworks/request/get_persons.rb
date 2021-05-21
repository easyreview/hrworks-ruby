# frozen_string_literal: true

module Hrworks
  class Request
    # Lists all persons in the company (or in the specifiedorganization units).
    # By default, only activepersons are returned. Each person that was neither
    # deleted nor has left the company counts asactive.
    class GetPersons < ::Hrworks::Request
      TARGET = "GetPersons"

      def initialize(organizational_units: nil, only_active: nil)
        @data = {
          "organizationUnits" => organizational_units,
          "onlyActive" => only_active
        }.compact

        super
      end
    end
  end
end
