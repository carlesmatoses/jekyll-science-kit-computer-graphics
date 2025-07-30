# glb_viewer_tag.rb 

module JekyllSkcg
  class GlbViewerTag < Liquid::Tag
    def initialize(tag_name, markup, tokens)
      super
      @attributes = {}
      markup.scan(/(\w+)\s*=\s*['"]([^'"]+)['"]/i) do |key, value|
        @attributes[key] = value
      end
    end

    def render(context)
      id = @attributes["id"] || "viewer-#{rand(1000)}"
      models = @attributes["models"] || ""
      materials = @attributes["materials"] || ""

      models_array = models.split(',').map { |m| '"' + m.strip + '"' }.join(',')
      materials_array = materials.split(',').map { |m| '"' + m.strip + '"' }.join(',')

      <<~HTML
        <div class="glb-viewer"
             data-id="#{id}"
             data-models='[#{models_array}]'
             data-materials='[#{materials_array}]'>
        </div>
      HTML
    end
  end
end

Liquid::Template.register_tag('glb_viewer', JekyllSkcg::GlbViewerTag)