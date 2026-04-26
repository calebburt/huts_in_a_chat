module MarkdownHelper
  require "redcarpet"

  # Custom renderer with safe HTML filtering
  class HTMLRenderer < Redcarpet::Render::HTML
    def block_code(code, language)
      # Optional: syntax highlighting with Rouge
      begin
        require "rouge"
        formatter = Rouge::Formatters::HTML.new
        lexer = Rouge::Lexer.find_fancy(language || "plaintext", code) || Rouge::Lexers::PlainText
        formatter.format(lexer.lex(code))
      rescue LoadError
        # Fallback if Rouge is not installed
        "<pre><code>#{ERB::Util.html_escape(code)}</code></pre>"
      end
    end
  end

  def render_markdown(text)
    return "" if text.blank?

    renderer = HTMLRenderer.new(
      filter_html: true,       # Strip raw HTML tags
      escape_html: true,       # Belt-and-braces: HTML-escape any that survive
      safe_links_only: true,   # Block javascript:/data: URLs in [text](url) and ![](url)
      no_styles: true,         # Strip <style> in case filter_html is bypassed
      hard_wrap: true
    )

    options = {
      fenced_code_blocks: true,
      autolink: true,
      tables: true,
      strikethrough: true,
      lax_spacing: true
    }

    markdown = Redcarpet::Markdown.new(renderer, options)
    markdown.render(text).html_safe
  end
end
