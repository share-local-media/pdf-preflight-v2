# coding: utf-8

module Preflight
  module Rules
    # Every PDF has an optional 'Info' dictionary. Check that the target file
    # has certain keys and that the keys match a given regexp
    #
    # Arguments: the required keys
    #
    # Usage:
    #
    #   class MyPreflight
    #     include Preflight::Profile
    #
    #     rule Preflight::Rules::MatchInfoPdfxVersions,
    #       [{:GTS_PDFXVersion => /\APDF\/X/, :GTS_PDFXConformance => /\APDF\/X-1a/}, {:GTS_PDFXVersion => /\APDF\/X-4/}]
    #   end
    #
    class MatchInfoPdfxVersions

      def initialize(matches = {})
        @matches = matches
      end

      def check_hash(ohash)
        errors   = {}
        versions = []
        info     = ohash.object(ohash.trailer[:Info])

        if info.nil?
          return [Issue.new("Info dict definition is missing", self)]
        elsif !@matches.is_a?(Hash)
          raise ArgumentError, "matches have to be a hash of hashes"
        else
          @matches.each do |pdfx_version, version_required_attrs|
            Preflight::Rules::MatchInfoEntries.new(version_required_attrs).
              then { |checker|
                versions     << pdfx_version
                check_result = checker.check_hash(ohash)

                if check_result.any?
                  unsatisfied_attributes = check_result.map(&:attributes).map {|error_set| error_set }.map(&:to_s)
                  errors[pdfx_version] = Issue.new(
                    "Invalid file for #{pdfx_version}. Next attributes are missing or are invalid: #{unsatisfied_attributes}",
                    self,
                    unsatisfied_attributes
                  )
                end
              }
          end
        end

        # return empty array if file was at least compliant with
        # one PDFX format
        return [] if (versions - errors.keys).any?

        errors.values
      end
    end
  end
end
