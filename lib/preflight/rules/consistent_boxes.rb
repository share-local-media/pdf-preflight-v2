# coding: utf-8

require 'bigdecimal'

module Preflight
  module Rules

    # Checks all page boxes (MediaBox, CropBox, etc) are consistent across every
    # page in the PDF. Useful to ensure a PDF will print consistently.
    #
    # Arguments: none
    #
    # Usage:
    #
    #   class MyPreflight
    #     include Preflight::Profile
    #
    #     rule Preflight::Rules::ConsistentBoxes
    #   end
    #
    class ConsistentBoxes
      # tolerance of 0.03 pts when comparing numbers
      DEFAULT_TOLERANCE = (BigDecimal("-0.03")..BigDecimal("0.03"))

      attr_reader :issues

      def initialize(tolerance = DEFAULT_TOLERANCE)
        @tolerance = tolerance
        @boxes = {}
        @issues = []
      end

      def page=(page)
        dict = page.attributes

        %i(MediaBox CropBox TrimBox ArtBox BleedBox).each do |box|
          if dict[box]
            @boxes[box] ||= {}
            @boxes[box][page.number] = dict[box]
          end
        end

        check_consistency if page.number > 1
      end

      private

      def check_consistency
        @boxes.each do |name, sizes|
          if sizes.size > 1
            points = sizes.values
            first_box  = points.first

            points[1,points.size].each_with_index do |this_box, idx|
              page_num = idx + 2
              if !boxes_match?(first_box, this_box)
                @issues << Issue.new("#{name} must be consistent across all pages",
                                   self,
                                   :page => page_num,
                                   :box  => name)
              end
            end
          end
        end
      end

      def boxes_match?(box1, box2)
        diffs = box1.zip(box2).map { |a,b| BigDecimal(a.to_s) - BigDecimal(b.to_s) }
        diffs.all? { |diff| @tolerance.include?(diff) }
      end

    end
  end
end
