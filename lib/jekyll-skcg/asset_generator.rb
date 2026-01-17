# frozen_string_literal: true

require 'fileutils'

module JekyllSkcg
  # Generator that copies assets from the gem to the site
  class AssetGenerator < Jekyll::Generator
    safe true
    
    def generate(site)
      # __dir__ is lib/jekyll-skcg, go up one level to lib, then access assets subdirectory
      gem_lib_path = File.expand_path('..', __dir__)
      gem_assets_path = File.join(gem_lib_path, 'assets')
      
      return unless Dir.exist?(gem_assets_path)
      
      # Copy all files from gem assets to site assets
      dest = File.join(site.source, 'assets', 'jekyll-skcg')
      copy_directory(gem_assets_path, dest, site)
    end
    
    private
    
    def copy_directory(src_dir, dest_dir, site)
      FileUtils.mkdir_p(dest_dir)
      
      Dir.glob(File.join(src_dir, '**', '*')).each do |file|
        next if File.directory?(file)
        
        relative_path = file.sub("#{src_dir}/", '')
        dest_file = File.join(dest_dir, relative_path)
        
        FileUtils.mkdir_p(File.dirname(dest_file))
        FileUtils.cp(file, dest_file)
        
        # Add to Jekyll's static files so they get copied to _site
        site.static_files << Jekyll::StaticFile.new(
          site,
          site.source,
          File.dirname(dest_file.sub("#{site.source}/", '')),
          File.basename(dest_file)
        )
      end
    end
  end
end
