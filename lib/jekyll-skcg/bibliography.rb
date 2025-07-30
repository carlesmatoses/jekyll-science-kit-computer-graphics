# bibliography.rb
require 'bibtex'
require 'cgi'

module JekyllSkcg
  module Bibliography
    class Loader < Liquid::Tag
      def initialize(tag_name, text, tokens)
        super
        @bibfile = text.strip
      end

      def render(context)
        site = context.registers[:site]
        bib_path = File.join(site.source, @bibfile)

        bib = BibTeX.open(bib_path, filter: :latex)

        site.data["references"] = {}
        site.data["citations_used"] = []

        bib.each do |entry|
          key = entry.key.to_s

          site.data["references"][key] = {
            "key" => key,
            "title" => entry[:title] ? entry[:title].to_s : "Untitled",
            "author" => entry[:author] ? entry[:author].to_s.gsub(" and ", ", ") : "Unknown Author",
            "year" => entry[:year] ? entry[:year].to_s : "Unknown Year",
            "publisher" => entry[:publisher] ? entry[:publisher].to_s : nil,
            "journal" => entry[:journal] ? entry[:journal].to_s : nil,
            "volume" => entry[:volume] ? entry[:volume].to_s : nil,
            "pages" => entry[:pages] ? entry[:pages].to_s : nil,
            "doi" => entry[:doi] ? "https://doi.org/#{entry[:doi]}" : nil,
            "url" => entry[:url] ? entry[:url].to_s : nil
          }
        end

        ""
      end
    end

    class BibliographyTag < Liquid::Tag
      def render(context)
        site = context.registers[:site]
        references = site.data["references"] || {}

        html = "<div class='bibliography'>"
        references.each do |key, entry|
          title     = h(entry["title"])
          authors   = h(entry["author"])
          year      = h(entry["year"])
          publisher = h(entry["publisher"])
          journal   = entry["journal"] ? "<i>#{h(entry["journal"])}</i>" : nil
          volume    = entry["volume"] ? "Vol. #{h(entry["volume"])}" : nil
          pages     = entry["pages"] ? "pp. #{h(entry["pages"])}" : nil
          doi       = entry["doi"] ? "<a href='#{entry["doi"]}'>DOI</a>" : nil
          url       = entry["url"] ? "<a href='#{entry["url"]}'>Link</a>" : nil

          html << "<p id='#{key}'>"
          html << "<strong>#{title}</strong><br>"
          html << "#{authors}<br>"
          html << "#{year}<br>" if year
          html << "#{publisher}<br>" if publisher
          html << "#{[journal, volume, pages].compact.join(', ')}<br>" if journal || volume || pages
          html << "#{[doi, url].compact.join(' | ')}" if doi || url
          html << "</p>\n"
        end
        html << "</div>\n"
        html
      end

      private

      def h(text)
        CGI.escapeHTML(text.to_s)
      end
    end

    class CiteTag < Liquid::Tag
      def initialize(tag_name, text, tokens)
        super
        @key = text.strip
      end

      def render(context)
        site = context.registers[:site]
        references = site.data["references"] || {}
        site.data["citations_used"] ||= []

        if references[@key]
          site.data["citations_used"] << @key unless site.data["citations_used"].include?(@key)

          ref = references[@key]
          title = h(ref["title"])
          url = ref["url"]

          if url
            "<a href='#{url}'>#{title}</a>"
          else
            "<a href='##{@key}'>#{title}</a>"
          end
        else
          "<span class='missing-ref'>[Missing: #{@key}]</span>"
        end
      end

      private

      def h(text)
        CGI.escapeHTML(text.to_s)
      end
    end
  end
end

Liquid::Template.register_tag('bibliography_loader', JekyllSkcg::Bibliography::Loader)
Liquid::Template.register_tag('bibliography', JekyllSkcg::Bibliography::BibliographyTag)
Liquid::Template.register_tag('cite', JekyllSkcg::Bibliography::CiteTag)
