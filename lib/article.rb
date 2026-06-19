require 'front_matter_parser'
require 'kramdown'
require 'kramdown-parser-gfm'
require 'date'

class Article
  MONTH_NAMES = {
    1 => 'January', 2 => 'February', 3 => 'March', 4 => 'April',
    5 => 'May', 6 => 'June', 7 => 'July', 8 => 'August',
    9 => 'September', 10 => 'October', 11 => 'November', 12 => 'December'
  }.freeze

  COVER_EXTENSIONS = %w[webp png jpg jpeg].freeze

  MONTH_ABBR_MAP = {
    'jan' => 1, 'feb' => 2, 'mar' => 3, 'apr' => 4,
    'may' => 5, 'jun' => 6, 'jul' => 7, 'aug' => 8,
    'sep' => 9, 'oct' => 10, 'nov' => 11, 'dec' => 12
  }.freeze

  attr_reader :title, :date, :event_date, :excerpt, :content_md, :slug, :lang,
              :date_path, :file_path, :month, :day, :popular, :cover_path, :thumb_path, :hero_path, :year,
              :author, :topics, :people, :organizations, :technologies, :sources,
              :updated_at, :alternate_url

  def self.parse(file_path, site_root: '.')
    raw = File.read(file_path)
    parsed = FrontMatterParser::Parser.new(:md).call(raw)

    abs_articles = File.expand_path('articles', site_root)
    rel_path = file_path.delete_prefix(abs_articles + '/')
    parts = rel_path.split('/')
    lang       = parts[0]
    month_name = parts[1]
    day_str    = parts[2]
    dir_name   = parts[3]
    slug       = dir_name.tr('_', '-')

    month     = MONTH_ABBR_MAP[month_name.downcase]
    day       = day_str.to_i
    date_path = "#{month_name}/#{day}"

    article_dir = File.dirname(file_path)
    cover = COVER_EXTENSIONS.map { |ext| File.join(article_dir, "cover.#{ext}") }
                             .find { |path| File.exist?(path) }
    thumb = File.join(article_dir, 'thumb.webp')
    thumb = nil unless File.exist?(thumb)
    hero = File.join(article_dir, 'hero.webp')
    hero = nil unless File.exist?(hero)

    front_matter = parsed.front_matter
    raw_date = front_matter['date']
    event_date = normalize_event_date(front_matter['event_date'], raw_date)
    year = front_matter['event_year'] || extract_year(raw_date) || event_date&.year

    new(
      title:      front_matter['title'] || slug.gsub('-', ' ').capitalize,
      date:       raw_date,
      event_date: event_date,
      excerpt:    front_matter['excerpt'] || extract_excerpt(parsed.content),
      content_md: parsed.content,
      lang:       lang,
      date_path:  date_path,
      slug:       slug,
      month:      month,
      day:        day,
      year:       year,
      popular:    front_matter['popular'] || false,
      author:     front_matter['author'],
      topics:     normalize_list(front_matter['topics']),
      people:     normalize_list(front_matter['people']),
      organizations: normalize_list(front_matter['organizations']),
      technologies: normalize_list(front_matter['technologies']),
      sources:    normalize_sources(front_matter['sources']),
      updated_at:    front_matter['updated_at'],
      alternate_url: front_matter[lang == 'en' ? 'ru' : 'en'],
      file_path:  file_path,
      cover_path: cover,
      thumb_path: thumb,
      hero_path:  hero
    )
  end

  def self.normalize_event_date(event_date, raw_date)
    return event_date if event_date.is_a?(Date)
    return Date.iso8601(event_date.to_s) if event_date && !event_date.to_s.empty?
    return nil unless raw_date

    parsed = Date.parse(raw_date.to_s)
    raw_year = extract_year(raw_date)
    return nil if raw_year && parsed.year != raw_year

    parsed
  rescue ArgumentError
    nil
  end

  def self.extract_year(raw_date)
    raw_date.to_s.match(/(\d{4})/)&.[](1)&.to_i
  end

  def self.normalize_list(value)
    case value
    when nil
      []
    when Array
      value.map(&:to_s).map(&:strip).reject(&:empty?)
    else
      value.to_s.split(',').map(&:strip).reject(&:empty?)
    end
  end

  def self.normalize_sources(value)
    Array(value).filter_map do |source|
      case source
      when Hash
        title = source['title'] || source[:title]
        url = source['url'] || source[:url]
        next if title.to_s.strip.empty? || url.to_s.strip.empty?

        { 'title' => title.to_s.strip, 'url' => url.to_s.strip }
      else
        url = source.to_s.strip
        next if url.empty?

        { 'title' => url, 'url' => url }
      end
    end
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

  def initialize(title:, date:, event_date:, excerpt:, content_md:, lang:, date_path:, slug:,
                 month:, day:, year:, popular:, author:, topics:, people:, organizations:, technologies:, sources:,
                 updated_at:, alternate_url:,
                 file_path:, cover_path: nil, thumb_path: nil, hero_path: nil)
    @title      = title
    @date       = date
    @event_date = event_date
    @excerpt    = excerpt
    @content_md = content_md
    @lang       = lang
    @date_path  = date_path
    @slug       = slug
    @month      = month
    @day        = day
    @year       = year
    @popular    = popular
    @author     = author
    @topics     = topics
    @people     = people
    @organizations = organizations
    @technologies = technologies
    @sources      = sources
    @updated_at   = updated_at
    @alternate_url = alternate_url
    @file_path  = file_path
    @cover_path = cover_path
    @thumb_path = thumb_path
    @hero_path  = hero_path
  end

  def cover?
    !cover_path.nil?
  end

  def cover_url
    "#{url}/#{File.basename(cover_path)}"
  end

  def thumb_url
    thumb_path ? "#{url}/thumb.webp" : cover_url
  end

  def hero_url
    hero_path ? "#{url}/hero.webp" : cover_url
  end

  def content_html
    html = Kramdown::Document.new(autolinked_md, input: 'GFM').to_html
    html.gsub(/<a href=/, '<a target="_blank" rel="noopener noreferrer" href=')
  end

  def key_facts
    facts = []
    facts << ['Event date', event_date.iso8601] if event_date
    facts << ['People', people.join(', ')] unless people.empty?
    facts << ['Organizations', organizations.join(', ')] unless organizations.empty?
    facts << ['Technologies', technologies.join(', ')] unless technologies.empty?
    facts << ['Topics', topics.join(', ')] unless topics.empty?
    facts
  end

  def modified_date
    File.mtime(file_path).utc.to_date.iso8601
  end

  def word_count
    content_md
      .gsub(/```.*?```/m, ' ')
      .gsub(/\[([^\]]+)\]\([^)]+\)/, '\1')
      .gsub(/[#*_>`\-\[\]().,;:!?"]/, ' ')
      .split
      .size
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

  private

  # kramdown-parser-gfm doesn't implement GFM extended autolinks (bare URLs).
  # Convert bare https?:// URLs to angle-bracket autolinks so kramdown renders
  # them as <a> tags. Skip URLs already inside markdown links [t](url),
  # code spans `url`, or angle brackets <url>.
  def autolinked_md
    content_md.gsub(/(?<![(\[<`"])(https?:\/\/[^\s\])"<`]+)/) { "<#{$1}>" }
  end
end
