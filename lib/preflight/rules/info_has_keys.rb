# coding: utf-8

module Preflight
  module Rules

    # Every PDF has an optional 'Info' dictionary. Check that the target file
    # has certain keys
    #
    # Arguments: the required keys
    #
    # Usage:
    #
    #   class MyPreflight
    #     include Preflight::Profile
    #
    #     rule Preflight::Rules::InfoHasKeys, :Title, :CreationDate, :ModDate
    #   end
    #
    class InfoHasKeys

      def initialize(*keys)
        @keys = keys.flatten
      end

      def check_hash(ohash)
        array = []
        info = ohash.object(ohash.trailer[:Info])
        if info.nil?
          array << Issue.new("Info dict definition is missing", self, :key => key)
        else
          missing = @keys - info.keys
          missing.map { |key|
            array << Issue.new("Info dict missing required key", self, :key => key)
          }
        end
        array
      end
    end
  end
end
