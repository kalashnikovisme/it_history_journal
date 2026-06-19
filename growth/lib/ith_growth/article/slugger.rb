module IthGrowth
  module Article
    class Slugger
      def self.slug(value)
        base = File.basename(value.to_s, File.extname(value.to_s))
        base = value.to_s if base.empty?
        base.downcase
            .gsub(/[^a-z0-9]+/, "-")
            .gsub(/\A-|-+\z/, "")
            .then { |slug| slug.empty? ? "article" : slug }
      end
    end
  end
end
