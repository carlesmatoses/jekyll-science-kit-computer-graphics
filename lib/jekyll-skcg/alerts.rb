# alerts.rb
module JekyllSkcg
  class AlertBlock < Liquid::Block
    def initialize(tag_name, text, tokens)
      super
      @type = text.strip.split(' ', 2)[0] || 'primary'
    end

    def render(context)
      site = context.registers[:site]
      converter = site.find_converter_instance(Jekyll::Converters::Markdown)
      content = super.strip
      html_content = converter.convert(content)
      %Q(<div class="alert alert-#{@type}" role="alert">#{html_content}</div>)
    end
  end
end

Liquid::Template.register_tag('alert', JekyllSkcg::AlertBlock)