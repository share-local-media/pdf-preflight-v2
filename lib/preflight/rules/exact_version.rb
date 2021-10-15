# coding: utf-8

module Preflight
  module Rules
    # ensure the PDF version of the file under review is not more recent
    # than desired
    #
    # Arguments: the maximum version
    #
    # Usage:
    #
    #   class MyPreflight
    #     include Preflight::Profile
    #
    #     rule Preflight::Rules::ExactVersion, 1.6
    #   end
    #
    class ExactVersion

      def initialize(exact_version)
        @exact_version = exact_version.to_f
      end

      def check_hash(ohash)
        if ohash.pdf_version.to_f != @exact_version
          [Issue.new("PDF version should be #{@exact_version}", self,
                     :exact_version => @exact_version, :current_version => ohash.pdf_version)]
        else
          []
        end
      end
    end
  end
end
