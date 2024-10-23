require 'ostruct'

module Preflight
  module Rules
    class ImageColorspace
      DEVICE_SPACES = [:DeviceRGB, :DeviceCMYK, :DeviceGray]

      class ColorSpaceInfo
        # Move ICC_PROFILES to class level
        ICC_PROFILES = {
          'Adobe RGB (1998)' => /AdobeRGB1998/i,
          'sRGB' => /sRGB|IEC.*61966/i,
          'ProPhoto RGB' => /ProPhoto|ROMM/i,
          'Display P3' => /Display.*P3/i,
          'Adobe CMYK' => /U.S. Web Coated \(SWOP\)|Coated FOGRA/i
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
          puts "DEBUG: xobject: #{xobject.hash.inspect}" if $DEBUG
          raise
        end

        # Move to_s out of private section
        def to_s
          details = ["[ColorSpaceInfo]"]
          details << "Type: #{@base_type}"
          details << "ICC Profile: #{@icc_profile}" if @icc_profile
          details << "Components: #{@components}" if @components
          details << "Bits/Component: #{@bit_depth}" if @bit_depth
          details << "Rendering Intent: #{@rendering_intent}" if @rendering_intent
          details << "Has Alpha Channel" if @has_alpha
          details << "Indexed Base: #{@indexed_base}" if @indexed_base
          details.join(", ")
        end

        private

        def has_alpha?(xobject)
          smask = xobject.hash[:SMask]
          mask = xobject.hash[:Mask]

          puts "DEBUG: Checking alpha - SMask: #{smask.inspect}, Mask: #{mask.inspect}" if $DEBUG

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
          puts "DEBUG: Processing ColorSpace: #{cs.inspect}" if $DEBUG

          case cs
          when Symbol
            @base_type = cs
            @components = components_for_device_space(cs)
          when Array
            parse_array_colorspace(cs)
            # Map ICC profiles to their device equivalents for testing
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

          # Extract ICC profile details
          if profile_stream.hash[:Metadata]
            @icc_profile = extract_icc_metadata(profile_stream.hash[:Metadata])
          end

          # If we can't get the actual profile name, map based on components
          @icc_profile ||= case @components
                          when 1 then :DeviceGray
                          when 3 then :DeviceRGB
                          when 4 then :DeviceCMYK
                          else nil
                          end

          puts "DEBUG: ICC Profile details:" if $DEBUG
          puts "  - Stream: #{profile_stream.hash.inspect}" if $DEBUG
          puts "  - Components: #{@components}" if $DEBUG
          puts "  - Profile Name: #{@icc_profile}" if $DEBUG
          puts "  - Alternate: #{profile_stream.hash[:Alternate]}" if $DEBUG
          puts "  - Range: #{profile_stream.hash[:Range]}" if $DEBUG

          # Try to identify common ICC profiles
          identify_icc_profile(profile_stream)
        end

        def identify_icc_profile(profile_stream)
          return unless profile_stream.is_a?(PDF::Reader::Stream)

          # Get the raw stream data
          stream_data = profile_stream.data.to_s

          # Check stream data for profile signatures
          ICC_PROFILES.each do |name, pattern|
            if stream_data.match?(pattern)
              @icc_profile = name
              puts "DEBUG: Identified ICC Profile: #{name}" if $DEBUG
              break
            end
          end

          # Check metadata if available
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
            # Try to parse XMP metadata
            content = metadata.data.to_s
            if content.include?('xpacket') # XMP metadata
              # Extract profile name from XMP
              if content =~ /photoshop:ICCProfile>(.*?)</
                profile_name = $1
                puts "DEBUG: Found ICC Profile name in XMP: #{profile_name}" if $DEBUG
                return profile_name
              end
            end
          rescue => e
            puts "DEBUG: Error parsing ICC metadata: #{e.message}" if $DEBUG
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

      def initialize(*allowed_spaces)
        @allowed_spaces = allowed_spaces.flatten # Add flatten to handle arrays
        puts "DEBUG: Initialized with allowed spaces: #{@allowed_spaces.inspect}" if $DEBUG
      end

      def check_page(page)
        issues = []
        puts "DEBUG: Checking page for images" if $DEBUG

        page.xobjects.each do |name, xobject|
          puts "DEBUG: Processing XObject '#{name}': #{xobject.hash.inspect}" if $DEBUG
          next unless xobject.hash[:Subtype] == :Image

          begin
            color_info = ColorSpaceInfo.new(xobject)
            puts "DEBUG: Created ColorSpaceInfo for '#{name}': #{color_info}" if $DEBUG

            unless valid_colorspace?(color_info)
              issue = Issue.new(
                "Image '#{name}' has invalid color space: #{color_info}",
                self,
                {
                  page: page.number,
                  colorspace: color_info.base_type,
                  message: "invalid color space"
                }
              )
              puts "DEBUG: Found issue: #{issue.inspect}" if $DEBUG
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
    end
  end
end
