require 'pdf/reader'

require 'preflight/measurements'
require 'preflight/issue'
require 'preflight/profile'

require 'preflight/rules'
require 'preflight/profiles'
require 'preflight/rules/image_colorspace'  # Add this line

module Preflight
  VERSION = "0.0.6"

  module Rules
    autoload :ImageColorspace,     'preflight/rules/image_colorspace'  # Add this line
  end
end
