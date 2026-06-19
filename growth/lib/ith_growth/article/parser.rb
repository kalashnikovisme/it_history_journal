require "yaml"

module IthGrowth
  module Article
    ParsedArticle = Struct.new(:path, :title, :body, :frontmatter, :slug, keyword_init: true)

    class Parser
      def parse(path)
        content = File.read(path)
        frontmatter, body = split_frontmatter(content)
        title = frontmatter["title"] || markdown_title(body) || File.basename(path, File.extname(path))
        ParsedArticle.new(
          path: path,
          title: title,
          body: body.strip,
          frontmatter: frontmatter,
          slug: Slugger.slug(frontmatter["slug"] || title || path)
        )
      end

      private

      def split_frontmatter(content)
        return [{}, content] unless content.start_with?("---\n")

        _, yaml, body = content.split(/^---\s*$/, 3)
        [YAML.safe_load(yaml, aliases: true) || {}, body || ""]
      rescue Psych::SyntaxError
        [{}, content]
      end

      def markdown_title(body)
        body.lines.find { |line| line.start_with?("# ") }&.sub(/^#\s+/, "")&.strip
      end
    end
  end
end
