require 'ostruct'

module Preflight
  module Rules
    class ImageColorspace
      DEVICE_SPACES = [:DeviceRGB, :DeviceCMYK, :DeviceGray]

      class ColorSpaceInfo
        ICC_PROFILES = {
          # RGB Profiles
          'Adobe RGB (1998)' => /AdobeRGB1998|Adobe RGB \(1998\)/i,
          'sRGB' => /sRGB|IEC.*61966/i,
          'ProPhoto RGB' => /ProPhoto|ROMM/i,
          'Display P3' => /Display.*P3/i,

          # CMYK Profiles
          'Adobe CMYK' => /U\.S\. Web Coated \(SWOP\)|Coated FOGRA/i,
          'Japan Color' => /Japan Color|Japan Standard/i,
          'FOGRA' => /FOGRA(?:27|39|51|52|54|59)/i,
          'GRACoL' => /GRACoL|GRACOL/i,
          'ISO Coated' => /ISO Coated|ISO.*Coated/i,
          'PSO' => /PSO.*Coated|PSO.*Uncoated/i,

          # Gray Profiles
          'Gray Gamma' => /Gray.*Gamma|Dot.*Gain/i,

          # Generic Profile Patterns
          'Generic RGB' => /ColorMatch|ECI-RGB/i,
          'Generic CMYK' => /Euroscale|Coated|Uncoated/i
        }.freeze

        attr_reader :base_type, :icc_profile, :components, :bit_depth,
                   :rendering_intent, :has_alpha, :indexed_base

        def initialize(xobject)
          @base_type = nil
          @icc_profile = nil
          @components = nil
          @bit_depth = xobject.hash[:BitsPerComponent]
          @rendering_intent = xobject.hash[:Intent]
          @has_alpha = has_alpha?(xobject)
          extract_colorspace_info(xobject)

          puts to_s
        rescue => e
          puts "DEBUG: Error initializing ColorSpaceInfo: #{e.message}" if $DEBUG
          raise
        end

        def to_s
          details = ["[ColorSpaceInfo]"]
          details << "Type: #{@base_type}"
          details << "ICC Profile: #{@icc_profile}" if @icc_profile
          details << "Components: #{@components}" if @components
          details << "Bits/Component: #{@bit_depth}" if @bit_depth
          details << "Rendering Intent: #{@rendering_intent}" if @rendering_intent
          details << "Has Alpha Channel" if @has_alpha
          details.join(", ")
        end

        private

        def has_alpha?(xobject)
          smask = xobject.hash[:SMask]
          mask = xobject.hash[:Mask]

          if smask.is_a?(PDF::Reader::Stream)
            true
          elsif mask.is_a?(Array) && !mask.empty?
            true
          elsif mask.is_a?(PDF::Reader::Stream)
            true
          else
            false
          end
        end

        def extract_colorspace_info(xobject)
          cs = xobject.hash[:ColorSpace]

          case cs
          when Symbol
            @base_type = cs
            @components = components_for_device_space(cs)
          when Array
            parse_array_colorspace(cs)
            if @base_type == :ICCBased && @icc_profile
              @base_type = @icc_profile
            end
          else
            puts "DEBUG: Unknown ColorSpace type: #{cs.class}" if $DEBUG
            @base_type = :Unknown
          end
          puts "DEBUG: Extracted base_type: #{@base_type}, components: #{@components}" if $DEBUG
        end

        def parse_array_colorspace(cs)
          space_type = cs[0]
          puts "DEBUG: Parsing array colorspace type: #{space_type}" if $DEBUG

          case space_type
          when :ICCBased
            parse_icc_profile(cs[1])
          when :Indexed
            @base_type = :Indexed
            @indexed_base = cs[1]
            @components = 1
          when :Separation
            @base_type = :Separation
            @components = 1
          when :DeviceN
            @base_type = :DeviceN
            @components = cs[1].length
          when :Lab
            @base_type = :Lab
            @components = 3
          else
            puts "DEBUG: Unknown array colorspace type: #{space_type}" if $DEBUG
            @base_type = space_type
          end
        end

        def parse_icc_profile(stream)
          @base_type = :ICCBased
          profile_stream = stream.is_a?(PDF::Reader::Stream) ? stream : stream
          @components = profile_stream.hash[:N]

          # Try to get ICC profile from metadata first
          if profile_stream.hash[:Metadata]
            @icc_profile = extract_icc_metadata(profile_stream.hash[:Metadata])
            puts "DEBUG: Found ICC profile in metadata: #{@icc_profile}" if $DEBUG
          end

          # If no ICC profile found in metadata, check the stream data
          if @icc_profile.nil? && profile_stream.is_a?(PDF::Reader::Stream)
            identify_icc_profile(profile_stream)
          end

          # If still no profile found, map based on components
          @icc_profile ||= case @components
                          when 1 then :DeviceGray
                          when 3 then :DeviceRGB
                          when 4 then :DeviceCMYK
                          else nil
                          end

          puts "DEBUG: Final ICC Profile determination:" if $DEBUG
          puts "  - Components: #{@components}" if $DEBUG
          puts "  - Profile Name: #{@icc_profile}" if $DEBUG
          puts "  - Alternate: #{profile_stream.hash[:Alternate]}" if $DEBUG
        end

        def identify_icc_profile(profile_stream)
          return unless profile_stream.is_a?(PDF::Reader::Stream)

          stream_data = profile_stream.data.to_s

          ICC_PROFILES.each do |name, pattern|
            if stream_data.match?(pattern)
              @icc_profile = name
              puts "DEBUG: Identified ICC Profile: #{name}" if $DEBUG
              break
            end
          end

          if profile_stream.hash[:Metadata]
            metadata = profile_stream.hash[:Metadata]
            if metadata.is_a?(PDF::Reader::Stream)
              metadata_content = metadata.data.to_s
              ICC_PROFILES.each do |name, pattern|
                if metadata_content.match?(pattern)
                  @icc_profile = name
                  puts "DEBUG: Identified ICC Profile from metadata: #{name}" if $DEBUG
                  break
                end
              end
            end
          end
        end

        def extract_icc_metadata(metadata)
          return nil unless metadata.is_a?(PDF::Reader::Stream)

          begin
            content = metadata.data.to_s
            puts "DEBUG: Parsing XMP metadata:" if $DEBUG

            # Check for photoshop:ICCProfile
            if content =~ /photoshop:ICCProfile=\"([^\"]+)\"/
              profile_name = $1
              puts "DEBUG: Found ICC Profile in photoshop:ICCProfile: #{profile_name}" if $DEBUG
              return profile_name
            end

            # Check for iccProfile tag
            if content =~ /iccProfile>(.*?)<\/iccProfile>/
              profile_name = $1
              puts "DEBUG: Found ICC Profile in iccProfile tag: #{profile_name}" if $DEBUG
              return profile_name
            end

            # Check for xmp:ICCProfile
            if content =~ /xmp:ICCProfile=\"([^\"]+)\"/
              profile_name = $1
              puts "DEBUG: Found ICC Profile in xmp:ICCProfile: #{profile_name}" if $DEBUG
              return profile_name
            end

            # Check for older style ICC profile references
            if content =~ /photoshop:ICCProfile>(.*?)</
              profile_name = $1
              puts "DEBUG: Found ICC Profile in legacy format: #{profile_name}" if $DEBUG
              return profile_name
            end

            puts "DEBUG: No ICC profile found in metadata" if $DEBUG
            nil
          rescue => e
            puts "DEBUG: Error parsing ICC metadata: #{e.message}" if $DEBUG
            puts "DEBUG: Metadata content: #{content[0..200]}..." if $DEBUG
            nil
          end
        end

        def components_for_device_space(space)
          case space
          when :DeviceRGB then 3
          when :DeviceCMYK then 4
          when :DeviceGray then 1
          end
        end
      end

      def initialize(*allowed_spaces, blacklist: [])
        @allowed_spaces = allowed_spaces.flatten
        @blacklist = blacklist
        puts "DEBUG: Initialized with allowed spaces: #{@allowed_spaces.inspect}, blacklist: #{@blacklist.inspect}" if $DEBUG
      end

      def check_page(page)
        issues = []
        puts "DEBUG: Checking page for images" if $DEBUG

        page.xobjects.each do |name, xobject|
          puts "DEBUG: Processing XObject '#{name}'" if $DEBUG
          next unless xobject.hash[:Subtype] == :Image

          begin
            color_info = ColorSpaceInfo.new(xobject)
            puts "DEBUG: Created ColorSpaceInfo for '#{name}': #{color_info}" if $DEBUG

            # Check for ICC profile in metadata directly
            if xobject.hash[:Metadata]
              metadata = xobject.hash[:Metadata]
              if metadata.is_a?(PDF::Reader::Stream)
                content = metadata.data.to_s
                if content =~ /photoshop:ICCProfile=\"([^\"]+)\"/
                  profile_name = $1
                  puts "DEBUG: Found ICC Profile in image metadata: #{profile_name}" if $DEBUG

                  if @blacklist.include?(profile_name)
                    issue = Issue.new(
                      "Image '#{name}' uses blacklisted ICC profile: #{profile_name}",
                      self,
                      {
                        page: page.number,
                        colorspace: profile_name,
                        message: "blacklisted color space"
                      }
                    )
                    puts "DEBUG: Found blacklisted profile issue: #{issue.inspect}" if $DEBUG
                    issues << issue
                    next
                  end
                end
              end
            end

            # Only check other color space rules if not already blacklisted
            if !valid_colorspace?(color_info)
              issue = Issue.new(
                "Image '#{name}' has invalid color space: #{color_info}",
                self,
                {
                  page: page.number,
                  colorspace: color_info.base_type,
                  message: "invalid color space"
                }
              )
              puts "DEBUG: Found invalid color space issue: #{issue.inspect}" if $DEBUG
              issues << issue
            end
          rescue => e
            puts "DEBUG: Error processing XObject '#{name}': #{e.message}" if $DEBUG
            issues << Issue.new(
              "Error processing image '#{name}': #{e.message}",
              self,
              {
                page: page.number,
                error: e.message
              }
            )
          end
        end

        issues
      end

      private

      def blacklisted?(color_info)
        # Check both ICC profile name and metadata
        if color_info.icc_profile && @blacklist.include?(color_info.icc_profile)
          puts "DEBUG: Color space #{color_info.icc_profile} is blacklisted" if $DEBUG
          true
        else
          false
        end
      end

      def valid_colorspace?(color_info)
        return true if @allowed_spaces.empty?

        puts "DEBUG: Validating colorspace: #{color_info.inspect}" if $DEBUG

        case color_info.base_type
        when :ICCBased, :DeviceRGB, :DeviceCMYK, :DeviceGray
          puts "DEBUG: Checking device/ICC color space against allowed spaces: #{@allowed_spaces}" if $DEBUG
          @allowed_spaces.include?(color_info.base_type) ||
            (color_info.icc_profile && @allowed_spaces.include?(color_info.icc_profile))
        when :Indexed
          puts "DEBUG: Checking indexed color space with base: #{color_info.indexed_base}" if $DEBUG
          mock_xobject = OpenStruct.new(hash: { ColorSpace: color_info.indexed_base })
          base_info = ColorSpaceInfo.new(mock_xobject)
          valid_colorspace?(base_info)
        when :DeviceN
          puts "DEBUG: Checking DeviceN color space" if $DEBUG
          @allowed_spaces.include?(:DeviceN)
        else
          puts "DEBUG: Checking if #{color_info.base_type} is in #{@allowed_spaces}" if $DEBUG
          @allowed_spaces.include?(color_info.base_type)
        end
      end

      def check_colorspace(obj)
        case obj
        when Hash
          check_hash_colorspace(obj)
        when Array
          check_array_colorspace(obj)
        else
          raise "Unknown colorspace: #{obj.inspect}"
        end
      end
    end
  end
end
