# coding: utf-8

module Preflight
  module Rules

    # Ensure the page count matches certain criteria.
    #
    # Arguments: An integer, range, :even or :odd
    #
    # Usage:
    #
    #   class MyPreflight
    #     include Preflight::Profile
    #
    #     rule Preflight::Rules::PageCount, 1
    #     rule Preflight::Rules::PageCount, 1..2
    #     rule Preflight::Rules::PageCount, [4, 8]
    #     rule Preflight::Rules::PageCount, :even
    #     rule Preflight::Rules::PageCount, :odd
    #   end
    #
    class PageCount

      def initialize(pattern)
        @pattern = pattern
      end

      def check_hash(ohash)
        # Get the root object
        root = ohash.object(ohash.trailer[:Root])
        # Get the pages object
        pages = ohash.object(root[:Pages])
        # Get the page count
        page_count = pages[:Count]

        case @pattern
        when Integer then check_numeric(page_count)
        when Range  then check_range(page_count)
        when Array  then check_array(page_count)
        when :even  then check_even(page_count)
        when :odd   then check_odd(page_count)
        else
          [Issue.new("PageCount: invalid pattern", self)]
        end
      end

      private

      def check_numeric(count)
        if count != @pattern
          [Issue.new("Page count must equal #{@pattern}", self, :pattern => :invalid, :count => count)]
        else
          []
        end
      end

      def check_range(count)
        if !@pattern.include?(count)
          [Issue.new("Page count must be between #{@pattern.min} and #{@pattern.max}", self, :pattern => @pattern, :count => count)]
        else
          []
        end
      end

      def check_array(count)
        if !@pattern.include?(count)
          [Issue.new("Page count must be one of #{@pattern.join(', ')}", self, :pattern => @pattern, :count => count)]
        else
          []
        end
      end

      def check_even(count)
        if count.odd?
          [Issue.new("Page count must be an even number", self, :pattern => @pattern, :count => count)]
        else
          []
        end
      end

      def check_odd(count)
        if count.even?
          [Issue.new("Page count must be an odd number", self, :pattern => @pattern, :count => count)]
        else
          []
        end
      end
    end
  end
end
