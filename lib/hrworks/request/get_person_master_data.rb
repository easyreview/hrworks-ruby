# frozen_string_literal: true

module Hrworks
  class Request
    # Returns the current master data of the specified persons.
    class GetPersonMasterData < ::Hrworks::Request
      TARGET = "GetPersonMasterData"

      def initialize(persons: [], use_personnel_numbers: false)
        @data = {
          "persons" => persons,
          "usePersonnelNumbers" => use_personnel_numbers
        }.compact

        super()
      end
    end
  end
end
