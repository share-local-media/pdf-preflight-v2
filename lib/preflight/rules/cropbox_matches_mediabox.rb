# coding: utf-8

require 'bigdecimal'

module Preflight
  module Rules

    # Checks the CropBox for every page matches the MediaBox. This is required by
    # some PDF standards.
    #
    # Arguments: none
    #
    # Usage:
    #
    #   class MyPreflight
    #     include Preflight::Profile
    #
    #     rule Preflight::Rules::CropboxMatchesMediabox
    #   end
    #
    class CropboxMatchesMediabox

      attr_reader :issues

      def page=(page)
        @issues = []
        dict = page.attributes

        if dict[:CropBox] && dict[:MediaBox] && round_off(dict[:CropBox]) != round_off(dict[:MediaBox])
          @issues << Issue.new("CropBox must match MediaBox", self, :page => page.number)
        end
      end

      private

      def round_off(*arr)
<<<<<<< HEAD
        arr.flatten.compact.map { |n| BigDecimal(n.to_s).round(2) }  # Changed from BigDecimal.new to BigDecimal
=======
        arr.flatten.compact.map { |n| BigDecimal(n.to_s).round(2) }
>>>>>>> old-fork/slm
      end
    end
  end
end
