# frozen_string_literal: true

module JekyllSkcg
  # Hook that injects required scripts and stylesheets into pages
  class ScriptInjector
    EXTERNAL_DEPENDENCIES = [
      # Three.js core
      { type: :script, url: 'https://cdnjs.cloudflare.com/ajax/libs/three.js/r128/three.min.js' },
      # Three.js addons
      { type: :script, url: 'https://cdn.jsdelivr.net/npm/fflate@0.8.2/umd/index.min.js' },
      { type: :script, url: 'https://cdn.jsdelivr.net/npm/three@0.128.0/examples/js/loaders/GLTFLoader.js' },
      { type: :script, url: 'https://cdn.jsdelivr.net/npm/three@0.128.0/examples/js/loaders/EXRLoader.js' },
      { type: :script, url: 'https://cdn.jsdelivr.net/npm/three@0.128.0/examples/js/controls/OrbitControls.js' },
      # dat.GUI
      { type: :script, url: 'https://cdnjs.cloudflare.com/ajax/libs/dat-gui/0.7.9/dat.gui.min.js' },
    ].freeze

    GEM_ASSETS = [
      { type: :stylesheet, url: '/assets/jekyll-skcg/css/science-kit-computer-graphics.css' },
      { type: :script, url: '/assets/jekyll-skcg/js/science-kit-computer-graphics.js' },
    ].freeze

    class << self
      def build_injection_html_public
        build_injection_html
      end
      
      def inject_into_document(document)
        puts "  Checking document: #{document.relative_path rescue document.path}"
        puts "    Extension: #{document.output_ext}"
        puts "    Has glb-viewer: #{document.content.include?('glb-viewer')}"
        
        return false unless document.output_ext == '.html'
        return false unless document.content.include?('glb-viewer') # Only inject if viewer is used
        
        content = document.output
        
        # Find </head> tag
        head_close_index = content.rindex('</head>')
        unless head_close_index
          puts "    No </head> tag found!"
          return false
        end
        
        # Build injection HTML
        injection = build_injection_html
        
        # Inject before </head>
        document.output = content[0...head_close_index] + injection + content[head_close_index..-1]
        puts "    ✅ Injected scripts and stylesheets!"
        true
      end

      private

      def build_injection_html
        html = "\n  <!-- Jekyll Science Kit Computer Graphics - Auto-injected dependencies -->\n"
        
        # Add external dependencies
        EXTERNAL_DEPENDENCIES.each do |dep|
          html += build_tag(dep)
        end
        
        # Add gem assets
        GEM_ASSETS.each do |asset|
          html += build_tag(asset)
        end
        
        html + "  <!-- End Jekyll Science Kit Computer Graphics dependencies -->\n"
      end

      def build_tag(asset)
        case asset[:type]
        when :script
          "  <script src=\"#{asset[:url]}\"></script>\n"
        when :stylesheet
          "  <link rel=\"stylesheet\" type=\"text/css\" href=\"#{asset[:url]}\">\n"
        end
      end
    end
  end
end

# Register the hook - use :post_write to modify files after they're written
Jekyll::Hooks.register :site, :post_write do |site|
  # Find all HTML files in _site that contain glb-viewer
  Dir.glob(File.join(site.dest, '**', '*.html')).each do |file_path|
    content = File.read(file_path)
    
    # Skip if no glb-viewer
    next unless content.include?('glb-viewer')
    
    # Skip if already injected
    next if content.include?('Jekyll Science Kit Computer Graphics - Auto-injected')
    
    # Find </head> and inject
    if content =~ /<\/head>/
      injection = JekyllSkcg::ScriptInjector.build_injection_html_public
      modified_content = content.sub('</head>', injection + '</head>')
      File.write(file_path, modified_content)
    end
  end
end
