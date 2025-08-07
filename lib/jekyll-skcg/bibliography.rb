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
      def initialize(tag_name, text, tokens)
        super
        @style = text.strip.downcase
        @style = "ieee" if @style.empty? # Default to IEEE style
      end

      def render(context)
        site = context.registers[:site]
        references = site.data["references"] || {}

        html = "<div class='bibliography bibliography-#{@style}'>"
        references.each do |key, entry|
          html << format_reference(key, entry, @style)
        end
        html << "</div>\n"
        html
      end

      private

      def format_reference(key, entry, style = "ieee")
        case style
        when "apa"
          format_apa_reference(key, entry)
        when "ieee"
          format_ieee_reference(key, entry)
        else
          format_ieee_reference(key, entry) # Default fallback
        end
      end

      def format_ieee_reference(key, entry)
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

        # Build citation parts with CSS classes (IEEE style)
        citation_parts = []
        
        # Authors (required)
        citation_parts << "<span class='bib-authors'>#{h(authors)}</span>" if authors && !authors.empty?
        
        # Title in quotes
        citation_parts << "<span class='bib-title'>\"#{h(title)}\"</span>" if title && !title.empty?
        
        # Journal/Publisher info
        if journal && !journal.empty?
          journal_part = "<span class='bib-journal'><i>#{h(journal)}</i></span>"
          if volume && !volume.empty?
            journal_part += ", vol. <span class='bib-volume'>#{h(volume)}</span>"
          end
          if pages && !pages.empty?
            journal_part += ", pp. <span class='bib-pages'>#{h(pages)}</span>"
          end
          if year && !year.empty?
            journal_part += ", <span class='bib-year'>#{h(year)}</span>"
          end
          citation_parts << journal_part
        elsif publisher && !publisher.empty?
          publisher_part = "<span class='bib-publisher'>#{h(publisher)}</span>"
          if year && !year.empty?
            publisher_part += ", <span class='bib-year'>#{h(year)}</span>"
          end
          citation_parts << publisher_part
        elsif year && !year.empty?
          citation_parts << "<span class='bib-year'>#{h(year)}</span>"
        end
        
        # Links
        links = []
        links << "<span class='bib-doi'><a href='#{doi}'>DOI</a></span>" if doi && !doi.empty?
        links << "<span class='bib-url'><a href='#{url}'>URL</a></span>" if url && !url.empty?
        citation_parts << links.join(" | ") unless links.empty?

        # Construct the final HTML
        html = "<p id='#{key}' class='bibliography-entry ieee-style' data-key='#{key}'>"
        html << citation_parts.join(", ")
        html << ".</p>\n"
        html
      end

      def format_apa_reference(key, entry)
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

        # Build citation parts with CSS classes (APA style)
        citation_parts = []
        
        # Authors (required)
        citation_parts << "<span class='bib-authors'>#{h(authors)}</span>" if authors && !authors.empty?
        
        # Year in parentheses
        citation_parts << "<span class='bib-year'>(#{h(year)})</span>" if year && !year.empty?
        
        # Title (no quotes in APA)
        citation_parts << "<span class='bib-title'>#{h(title)}</span>" if title && !title.empty?
        
        # Journal/Publisher info
        if journal && !journal.empty?
          journal_part = "<span class='bib-journal'><i>#{h(journal)}</i></span>"
          if volume && !volume.empty?
            journal_part += ", <span class='bib-volume'><i>#{h(volume)}</i></span>"
          end
          if pages && !pages.empty?
            journal_part += ", <span class='bib-pages'>#{h(pages)}</span>"
          end
          citation_parts << journal_part
        elsif publisher && !publisher.empty?
          citation_parts << "<span class='bib-publisher'>#{h(publisher)}</span>"
        end
        
        # Links
        links = []
        links << "<span class='bib-doi'><a href='#{doi}'>DOI</a></span>" if doi && !doi.empty?
        links << "<span class='bib-url'><a href='#{url}'>URL</a></span>" if url && !url.empty?
        citation_parts << links.join(" | ") unless links.empty?

        # Construct the final HTML
        html = "<p id='#{key}' class='bibliography-entry apa-style' data-key='#{key}'>"
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

          # Always link to local bibliography entry, like in academic papers
          "<a href='##{@key}' class='citation-link'>#{title}</a>"
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
