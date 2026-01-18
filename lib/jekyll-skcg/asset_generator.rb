# frozen_string_literal: true

module JekyllSkcg
  # Custom StaticFile that serves files from gem directory
  class GemStaticFile < Jekyll::StaticFile
    def initialize(site, base, dir, name, gem_path)
      super(site, base, dir, name)
      @gem_path = gem_path
    end

    # Override path to point to gem file
    def path
      File.join(@gem_path, @dir, @name)
    end

    # Override destination to place files in /assets/jekyll-skcg/
    def destination(dest)
      File.join(dest, 'assets', 'jekyll-skcg', @dir, @name)
    end
  end

  # Registers gem assets as static files without copying them to source
  # This is the standard Jekyll gem pattern - assets are served directly from gem directory
  class AssetGenerator
    class << self
      def setup
        Jekyll::Hooks.register :site, :after_reset do |site|
          register_gem_assets(site)
        end
      end

      private

      def register_gem_assets(site)
        # Get the gem's lib directory path
        # __dir__ is /site/_plugins/jekyll-science-kit-computer-graphics/lib/jekyll-skcg
        # We need /site/_plugins/jekyll-science-kit-computer-graphics/lib/assets
        gem_lib_path = File.expand_path('..', __dir__)  # Go up one level from jekyll-skcg to lib
        gem_assets_path = File.join(gem_lib_path, 'assets')
        
        return unless Dir.exist?(gem_assets_path)
        
        # Register all files in gem assets as Jekyll static files
        Dir.glob(File.join(gem_assets_path, '**', '*')).each do |file|
          next if File.directory?(file)
          
          # Calculate relative path from assets directory
          relative_path = file.sub("#{gem_assets_path}/", '')
          dirname = File.dirname(relative_path)
          basename = File.basename(file)
          
          # Create custom static file that serves from gem and writes to jekyll-skcg subdirectory
          static_file = GemStaticFile.new(site, site.source, dirname, basename, gem_assets_path)
          site.static_files << static_file
        end
      end
    end
  end
end

# Auto-setup when module is loaded
JekyllSkcg::AssetGenerator.setup
