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
    #       [{:GTS_PDFXVersion => /\APDF\/X/, :GTS_PDFXConformance => /\APDF\/X-1a/}, :GTS_PDFXVersion => /\APDF\/X-4/]
    #   end
    #
    class MatchInfoPdfxVersions

      def initialize(matches = {})
        @matches = matches
      end

      def check_hash(ohash)
        array = []
        info = ohash.object(ohash.trailer[:Info])

        if info.nil?
          array << Issue.new("Info dict definition is missing", self)
        elsif !@matches.is_a?(Array)
          raise ArgumentError, "matches have to be an array of hashes"
        else
          @matches.each do |info_elements|
            info_elements.each do |key, regexp|
              if !info.has_key?(key)
                array << Issue.new("Info dict missing required key #{key}", self, :key => key)
              elsif !info[key].to_s.match(regexp)
                array << Issue.new(
                  "value of Info entry #{key} doesn't match #{regexp}", self, :key => key, :regexp => regexp
                )
              end
            end
          end
        end

        array
      end
    end
  end
end
