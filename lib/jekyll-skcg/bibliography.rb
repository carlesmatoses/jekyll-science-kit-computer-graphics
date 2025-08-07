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
          html << format_reference(key, entry)
        end
        html << "</div>\n"
        html
      end

      private

      def format_reference(key, entry)
        # Extract and clean data
        title = entry["title"]
        authors = entry["author"]
        year = entry["year"]
        publisher = entry["publisher"]
        journal = entry["journal"]
        volume = entry["volume"]
        pages = entry["pages"]
        doi = entry["doi"]
        url = entry["url"]

        # Build citation parts
        citation_parts = []
        
        # Authors (required)
        citation_parts << h(authors) if authors && !authors.empty?
        
        # Year in parentheses
        citation_parts << "(#{h(year)})" if year && !year.empty?
        
        # Title in quotes
        citation_parts << "\"#{h(title)}\"" if title && !title.empty?
        
        # Journal/Publisher info
        if journal && !journal.empty?
          journal_part = "<i>#{h(journal)}</i>"
          if volume && !volume.empty?
            journal_part += ", #{h(volume)}"
          end
          if pages && !pages.empty?
            journal_part += ", #{h(pages)}"
          end
          citation_parts << journal_part
        elsif publisher && !publisher.empty?
          citation_parts << h(publisher)
        end
        
        # Links
        links = []
        links << "<a href='#{doi}'>DOI</a>" if doi && !doi.empty?
        links << "<a href='#{url}'>URL</a>" if url && !url.empty?
        citation_parts << links.join(" | ") unless links.empty?

        # Construct the final HTML
        html = "<p id='#{key}' class='bibliography-entry'>"
        html << citation_parts.join(". ")
        html << ".</p>\n"
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
