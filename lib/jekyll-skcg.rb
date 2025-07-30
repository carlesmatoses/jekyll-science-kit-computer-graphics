# frozen_string_literal: true

require_relative "jekyll-skcg/version"

puts "Loading Jekyll SKCG gem..."

module JekyllSkcg
  class Error < StandardError; end
end

# Load all extension files
require_relative "jekyll-skcg/bibliography"
require_relative "jekyll-skcg/reference_block"
require_relative "jekyll-skcg/alerts"
require_relative "jekyll-skcg/glb_viewer_tag"

puts "Jekyll SKCG gem loaded successfully!"