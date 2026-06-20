# reference_block.rb
module JekyllSkcg
  
  # Resolves {% ref type:id %} placeholders after each document renders,
  # once all referenceable blocks have self-registered their numbers.
  # this hook is called for both pages and documents (posts, collections, etc.) and 
  # it is executed after the document has been rendered, so we can safely modify the output.
  Jekyll::Hooks.register [:pages, :documents], :post_render do |doc|
    next unless doc.output

    # the already rendered document has a placeholder for each reference, we need to replace them with the actual numbers
    doc.output = doc.output.gsub(/<span class="ref-placeholder" data-ref-type="([^"]+)" data-ref-id="([^"]+)"><\/span>/) do
      type = $1
      id   = $2
      refs = doc.data["refs"] || {}
      number = refs.dig(type, id)

      if number
        "<a href='##{id}'>#{number}</a>"
      else
        "<span class='missing-ref'>[??]</span>"
      end
    end
  end

  class ReferenceableBlock < Liquid::Block
    attr_reader :attributes, :tag, :id

    def initialize(tag_name, markup, tokens)
      super
      @tag = tag_name
      @attributes = {}

      # Extract all key="value" pairs
      markup.scan(/(\w+)\s*=\s*"([^"]+)"/) do |key, value|
        @attributes[key] = value
      end

      @id = @attributes["id"]
    end

    def render(context)
      # Get the current page/post instead of site
      page = context.registers[:page]
      page["refs"] ||= {}
      page["refs"][@tag] ||= {}

      unless page["refs"][@tag].key?(@id)
        page["refs"][@tag][@id] = page["refs"][@tag].size + 1
      end

      number = page["refs"][@tag][@id]
      content = super.strip
      render_content(number, content)
    end

    def render_content(number, content)
      raise NotImplementedError
    end
  end

  class RefTag < Liquid::Tag
    def initialize(tag_name, markup, tokens)
      super
      @type, @id = markup.strip.split(':', 2)
    end

    def render(_context)
      "<span class=\"ref-placeholder\" data-ref-type=\"#{@type}\" data-ref-id=\"#{@id}\"></span>"
    end
  end

  class FigureBlock < ReferenceableBlock
    def render_content(number, content)
      width   = @attributes["width"] || "100%"
      caption = @attributes["caption"] || "Figure"
      id      = @id

      <<~HTML
        <figure id="#{id}" class="figure-block" style="width: #{width};" data-figure-number="#{number}">
          <div class="figure-content">
            #{content.strip}
          </div>
          <figcaption class="figure-caption">Fig. #{number}: #{caption}</figcaption>
        </figure>
      HTML
    end
  end

  # Base class for tags that live inside a {% figure %} block.
  # Subclasses implement +render_child(context)+ returning the inner HTML
  # (without the fig-child wrapper).
  class FigChildBlock < Liquid::Block
    def initialize(tag_name, markup, tokens)
      super
      @attributes = {}
      markup.scan(/(\w+)\s*=\s*"([^"]+)"/) { |k, v| @attributes[k] = v }
    end

    def render(context)
      width   = @attributes["width"] || "100%"
      caption = @attributes["caption"]
      inner   = render_child(context)

      caption_html = caption ? "<p class=\"fig-child-caption\">#{caption}</p>" : ""

      <<~HTML.strip
        <div class="fig-child" style="width: #{width};">
          #{inner.strip}
          #{caption_html}
        </div>
      HTML
    end

    def render_child(context)
      raise NotImplementedError
    end
  end

  class FigImageTag < Liquid::Tag
    YOUTUBE_RE = %r{(?:https?://)?(?:www\.)?(?:youtube\.com/watch\?v=|youtu\.be/)([\w-]+)}

    def initialize(tag_name, markup, tokens)
      super
      @attributes = {}
      markup.scan(/(\w+)\s*=\s*"([^"]+)"/) { |k, v| @attributes[k] = v }
    end

    def render(_context)
      width   = @attributes["width"] || "100%"
      src     = @attributes["src"] || ""
      alt     = @attributes["alt"] || ""
      caption = @attributes["caption"]

      inner_html = if (m = src.match(YOUTUBE_RE))
        youtube_id = m[1]
        <<~HTML.strip
          <div class="figure-video">
            <iframe src="https://www.youtube.com/embed/#{youtube_id}" title="#{alt}" frameborder="0" allowfullscreen></iframe>
          </div>
        HTML
      else
        "<img src=\"#{src}\" alt=\"#{alt}\" class=\"figure-image\">"
      end

      caption_html = caption ? "<p class=\"fig-child-caption\">#{caption}</p>" : ""

      <<~HTML.strip
        <div class="fig-child" style="width: #{width};">
          #{inner_html}
          #{caption_html}
        </div>
      HTML
    end
  end

  class FigMermaidBlock < FigChildBlock
    def render_child(context)
      code = super(context).strip  # Liquid::Block#render evaluates inner tags — we want raw text
      # super here calls Liquid::Block's render which processes inner liquid; we need raw content
      "<div class=\"mermaid\">#{nodelist.map { |n| n.respond_to?(:raw_value) ? n.raw_value : n.to_s }.join}</div>"
    end

    def render(context)
      width   = @attributes["width"] || "100%"
      caption = @attributes["caption"]

      # Collect raw text from nodelist (mermaid syntax must not be Liquid-processed)
      raw_code = nodelist.map(&:to_s).join.strip
      mermaid_html = "<div class=\"mermaid\">#{raw_code}</div>"
      caption_html = caption ? "<p class=\"fig-child-caption\">#{caption}</p>" : ""

      <<~HTML.strip
        <div class="fig-child" style="width: #{width};">
          #{mermaid_html}
          #{caption_html}
        </div>
      HTML
    end
  end

      
  class EquationBlock < ReferenceableBlock
    def render_content(number, content)
      equation_number = number
      label = @id

      <<~HTML
        <div id="#{label}" class="equation-block" style="display: flex; justify-content: space-between; align-items: center; margin: 1em 0;">
          <div style="flex: 1; overflow-x: auto; max-width: 100%;">
            <div style="min-width: max-content;">
              \\[
              #{content}
              \\]
            </div>
          </div>
          <div style="margin-left: 1em; white-space: nowrap;">(#{equation_number})</div>
        </div>
      HTML
    end
  end

end


class EquationInlineTag < Liquid::Tag
  def initialize(tag_name, markup, tokens)
    super
    @formula = markup.strip
  end

  def render(_context)
    # Output KaTeX/MathJax inline math delimiters
    "<span class=\"equation-inline\">$#{@formula}$</span>"
  end
end

Liquid::Template.register_tag('ref', JekyllSkcg::RefTag)
Liquid::Template.register_tag('referenceable_block', JekyllSkcg::ReferenceableBlock)
Liquid::Template.register_tag('figure', JekyllSkcg::FigureBlock)
Liquid::Template.register_tag('fig_img', JekyllSkcg::FigImageTag)
Liquid::Template.register_tag('fig_mermaid', JekyllSkcg::FigMermaidBlock)
Liquid::Template.register_tag('equation', JekyllSkcg::EquationBlock)
Liquid::Template.register_tag('equation_inline', EquationInlineTag)
