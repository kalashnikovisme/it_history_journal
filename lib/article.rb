require 'front_matter_parser'
require 'kramdown'
require 'kramdown-parser-gfm'

class Article
  MONTH_NAMES = {
    1 => 'January', 2 => 'February', 3 => 'March', 4 => 'April',
    5 => 'May', 6 => 'June', 7 => 'July', 8 => 'August',
    9 => 'September', 10 => 'October', 11 => 'November', 12 => 'December'
  }.freeze

  MONTH_ABBR_MAP = {
    'jan' => 1, 'feb' => 2, 'mar' => 3, 'apr' => 4,
    'may' => 5, 'jun' => 6, 'jul' => 7, 'aug' => 8,
    'sep' => 9, 'oct' => 10, 'nov' => 11, 'dec' => 12
  }.freeze

  attr_reader :title, :date, :excerpt, :content_md, :slug, :lang,
              :date_path, :file_path, :month, :day, :popular

  def self.parse(file_path, site_root: '.')
    raw = File.read(file_path)
    parsed = FrontMatterParser::Parser.new(:md).call(raw)

    abs_articles = File.expand_path('articles', site_root)
    rel_path = file_path.delete_prefix(abs_articles + '/')
    parts = rel_path.split('/')
    lang = parts[0]
    date_path = parts[1]
    filename = File.basename(file_path, '.md')
    slug = filename.tr('_', '-')

    month_abbr, day_str = date_path.split('-')
    month = MONTH_ABBR_MAP[month_abbr.downcase]
    day = day_str.to_i

    new(
      title:      parsed.front_matter['title'] || slug.gsub('-', ' ').capitalize,
      date:       parsed.front_matter['date'],
      excerpt:    parsed.front_matter['excerpt'] || extract_excerpt(parsed.content),
      content_md: parsed.content,
      lang:       lang,
      date_path:  date_path,
      slug:       slug,
      month:      month,
      day:        day,
      popular:    parsed.front_matter['popular'] || false,
      file_path:  file_path
    )
  end

  def self.extract_excerpt(content, max_length: 200)
    text = content
      .gsub(/^#+\s+.*$/, '')
      .gsub(/\[([^\]]+)\]\([^)]+\)/, '\1')
      .gsub(/\*\*?([^*]+)\*\*?/, '\1')
      .strip
    first_para = text.split(/\n\n+/).reject(&:empty?).first || ''
    first_para = first_para.strip.gsub(/\s+/, ' ')
    first_para.length > max_length ? "#{first_para[0, max_length]}..." : first_para
  end

  def initialize(title:, date:, excerpt:, content_md:, lang:, date_path:, slug:,
                 month:, day:, popular:, file_path:)
    @title      = title
    @date       = date
    @excerpt    = excerpt
    @content_md = content_md
    @lang       = lang
    @date_path  = date_path
    @slug       = slug
    @month      = month
    @day        = day
    @popular    = popular
    @file_path  = file_path
  end

  def content_html
    Kramdown::Document.new(content_md, input: 'GFM').to_html
  end

  def url
    "/#{lang}/#{date_path}/#{slug}"
  end

  def date_label
    "#{MONTH_NAMES[month]} #{day}"
  end

  def sort_key
    month * 100 + day
  end
end
