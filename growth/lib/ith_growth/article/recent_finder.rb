require "date"
require "ith_growth/article/parser"

module IthGrowth
  module Article
    class RecentFinder
      def initialize(content_dir:, parser: Parser.new)
        @content_dir = content_dir
        @parser = parser
      end

      def find(days: 7)
        find_by_date(Date.today - days)
      end

      def find_by_date(date)
        month = date.strftime("%b").downcase
        day   = date.day.to_s
        Dir.glob(File.join(@content_dir, "*", month, day, "*", "content.md")).sort.map do |path|
          article = @parser.parse(path)
          { path: path, date: date, article: article }
        end
      end
    end
  end
end
