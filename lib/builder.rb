require 'haml'
require 'fileutils'
require 'date'
require 'json'
require 'digest'
require_relative 'article'
require_relative 'render_scope'

class Builder
  TEMPLATES_DIR    = File.expand_path('../../templates', __FILE__)
  LANGUAGES        = %w[en ru].freeze
  ARTICLES_PER_PAGE = 20
  BASE_URL         = 'https://history.purple-magic.com'

  TRANSLATIONS = {
    'en' => {
      site_name:             'IT History Journal',
      latest_post:           'Latest post',
      today_in_history:      'On this day',
      recent_posts:          'Recent posts',
      popular_posts:         'Popular posts',
      related_posts:         'Related posts',
      all_articles:          'All Articles',
      more:                  'More',
      calendar:              'Calendar',
      home:                  'Home',
      read_more:             'Read more',
      lang_switch:           'RU',
      nav_label:             'Main navigation',
      browse_by_year:        'Browse by year',
      no_articles_this_year: 'No articles for this year yet.',
      months:                %w[January February March April May June
                                 July August September October November December]
    },
    'ru' => {
      site_name:             'IT History Journal',
      latest_post:           'Последняя запись',
      today_in_history:      'В этот день',
      recent_posts:          'Последние записи',
      popular_posts:         'Популярные записи',
      related_posts:         'Похожие статьи',
      all_articles:          'Все записи',
      more:                  'Ещё',
      calendar:              'Календарь',
      home:                  'Главная',
      read_more:             'Читать далее',
      lang_switch:           'EN',
      nav_label:             'Основная навигация',
      browse_by_year:        'По годам',
      no_articles_this_year: 'Статей за этот год пока нет.',
      months:                %w[Январь Февраль Март Апрель Май Июнь
                                 Июль Август Сентябрь Октябрь Ноябрь Декабрь]
    }
  }.freeze

  def initialize(site_root: '.', output_dir: '_site', articles_per_page: ARTICLES_PER_PAGE)
    @site_root        = File.expand_path(site_root)
    @output_dir       = File.expand_path(output_dir)
    @scope            = RenderScope.new
    @articles_per_page = articles_per_page
  end

  def build
    @css_fingerprint = nil
    FileUtils.rm_rf(@output_dir)
    FileUtils.mkdir_p(@output_dir)

    all_articles = load_articles
    build_redirect
    compile_css
    build_all_html(all_articles)
    copy_assets
    copy_favicon
  end

  def build_html
    all_articles = load_articles
    build_redirect
    build_all_html(all_articles)
  end

  def rebuild_article(file_path)
    all_articles = load_articles
    article      = Article.parse(file_path, site_root: @site_root)
    build_article(article, sorted_for_lang(all_articles, article.lang))
  end

  def rebuild_indexes
    all_articles = load_articles
    LANGUAGES.each do |lang|
      articles = sorted_for_lang(all_articles, lang)
      build_index(lang, articles)
      build_calendar(lang, articles)
      build_articles_pages(lang, articles)
      build_year_pages(lang, articles)
      build_rss(lang, articles)
    end
  end

  def load_articles
    Dir.glob(File.join(@site_root, 'articles', '**', 'content.md')).map do |path|
      Article.parse(path, site_root: @site_root)
    end
  end

  private

  def sorted_for_lang(all_articles, lang)
    all_articles.select { |a| a.lang == lang }.sort_by(&:sort_key).reverse
  end

  def build_all_html(all_articles)
    LANGUAGES.each do |lang|
      articles = sorted_for_lang(all_articles, lang)
      build_index(lang, articles)
      build_calendar(lang, articles)
      build_articles_pages(lang, articles)
      build_year_pages(lang, articles)
      build_rss(lang, articles)
      articles.each { |article| build_article(article, articles) }
    end
  end

  def build_redirect
    html = render_template('redirect', {})
    write_file('index.html', html)
  end

  def build_index(lang, articles)
    t     = TRANSLATIONS[lang]
    today = Date.today
    today_article = articles.find { |a| a.month == today.month && a.day == today.day }
    latest = today_article || articles.first
    latest_label = today_article ? t[:today_in_history] : t[:latest_post]
    recent = articles.reject { |a| a == latest }.first(20)
    popular = articles.select(&:popular).first(10)
    popular = recent.first(6) if popular.empty?

    days_with_articles = articles.each_with_object({}) do |a, h|
      h[[a.month, a.day]] = a.url
    end
    years_with_counts = articles.group_by(&:year)
                                .reject { |y, _| y.nil? }
                                .transform_values(&:count)
                                .sort_by { |y, _| y }

    inner = render_template('index', {
      lang:               lang,
      t:                  t,
      latest:             latest,
      latest_label:       latest_label,
      recent:             recent,
      popular:            popular,
      years_with_counts:  years_with_counts,
      days_with_articles: days_with_articles,
      current_month:      today.month,
      current_year:       today.year
    })
    html = wrap_layout(lang, t[:site_name], inner)
    write_file("#{lang}/index.html", html)
  end

  def build_articles_pages(lang, articles)
    t           = TRANSLATIONS[lang]
    total_count = articles.size
    pages       = articles.each_slice(@articles_per_page).to_a
    pages       = [[]] if pages.empty?
    total_pages = pages.size

    pages.each_with_index do |page_articles, idx|
      page_num = idx + 1
      inner = render_template('articles', {
        lang:        lang,
        t:           t,
        articles:    page_articles,
        page:        page_num,
        total_pages: total_pages,
        total_count: total_count
      })
      title = "#{t[:all_articles]} — #{t[:site_name]}"
      html  = wrap_layout(lang, title, inner)
      path  = page_num == 1 ? "#{lang}/articles/index.html" : "#{lang}/articles/#{page_num}/index.html"
      write_file(path, html)
    end
  end

  def build_article(article, all_lang_articles)
    t       = TRANSLATIONS[article.lang]
    related = all_lang_articles
      .reject { |a| a == article }
      .select { |a| a.month == article.month || a.date_path == article.date_path }
      .first(4)
    popular = all_lang_articles.select(&:popular).first(6)
    popular = all_lang_articles.first(6) if popular.empty?

    inner = render_template('article', {
      lang:    article.lang,
      t:       t,
      article: article,
      related: related,
      popular: popular
    })
    title = "#{article.title} — #{t[:site_name]}"
    og = {
      title:       article.title,
      description: article.excerpt,
      url:         "#{BASE_URL}#{article.url}/",
      image:       article.cover? ? "#{BASE_URL}#{article.cover_url}" : nil
    }
    jsonld = {
      '@context'        => 'https://schema.org',
      '@type'           => 'Article',
      'headline'        => article.title,
      'description'     => article.excerpt,
      'url'             => "#{BASE_URL}#{article.url}/",
      'inLanguage'      => article.lang,
      'publisher'       => { '@type' => 'Organization', 'name' => t[:site_name], 'url' => BASE_URL }
    }
    jsonld['datePublished'] = article.date if article.date
    jsonld['image']         = "#{BASE_URL}#{article.cover_url}" if article.cover?
    html  = wrap_layout(article.lang, title, inner, og: og, jsonld_json: jsonld.to_json)
    write_file("#{article.lang}/#{article.date_path}/#{article.slug}/index.html", html)

    if article.cover?
      dst = File.join(@output_dir, article.lang, article.date_path, article.slug, File.basename(article.cover_path))
      FileUtils.cp(article.cover_path, dst)
    end

    if article.thumb_path
      dst = File.join(@output_dir, article.lang, article.date_path, article.slug, 'thumb.webp')
      FileUtils.cp(article.thumb_path, dst)
    end

    if article.hero_path
      dst = File.join(@output_dir, article.lang, article.date_path, article.slug, 'hero.webp')
      FileUtils.cp(article.hero_path, dst)
    end
  end

  def build_calendar(lang, articles)
    t = TRANSLATIONS[lang]
    articles_by_month_day = articles.group_by { |a| [a.month, a.day] }

    inner = render_template('calendar', {
      lang:                  lang,
      t:                     t,
      articles_by_month_day: articles_by_month_day
    })
    title = "#{t[:calendar]} — #{t[:site_name]}"
    html  = wrap_layout(lang, title, inner)
    write_file("#{lang}/calendar/index.html", html)
  end

  def build_year_pages(lang, articles)
    t = TRANSLATIONS[lang]
    articles_by_year = articles.group_by(&:year).reject { |y, _| y.nil? }

    articles_by_year.each do |year, year_articles|
      sorted = year_articles.sort_by(&:sort_key)
      inner = render_template('year', {
        lang:     lang,
        t:        t,
        year:     year,
        articles: sorted
      })
      title = "#{year} — #{t[:site_name]}"
      html  = wrap_layout(lang, title, inner)
      write_file("#{lang}/#{year}/index.html", html)
    end
  end

  def css_fingerprint
    @css_fingerprint ||= begin
      path = File.join(@output_dir, 'assets', 'css', 'output.css')
      File.exist?(path) ? Digest::MD5.file(path).hexdigest[0, 8] : nil
    end
  end

  def wrap_layout(lang, title, content, og: nil, jsonld_json: nil)
    t = TRANSLATIONS[lang]
    render_template('layout', {
      lang:        lang,
      title:       title,
      t:           t,
      content:     content,
      year:        Date.today.year,
      og:          og,
      jsonld_json: jsonld_json,
      css_ver:     css_fingerprint
    })
  end

  def render_template(name, locals)
    path = File.join(TEMPLATES_DIR, "#{name}.html.haml")
    raise "Template not found: #{path}" unless File.exist?(path)
    src = File.read(path)
    Haml::Template.new { src }.render(@scope, locals)
  end

  def write_file(relative_path, content)
    full_path = File.join(@output_dir, relative_path)
    FileUtils.mkdir_p(File.dirname(full_path))
    File.write(full_path, content)
    full_path
  end

  def compile_css
    src = File.join(@site_root, 'assets', 'css', 'input.css')
    dst = File.join(@output_dir, 'assets', 'css', 'output.css')
    FileUtils.mkdir_p(File.dirname(dst))
    config = File.join(@site_root, 'tailwind.config.js')
    cmd = "bundle exec tailwindcss -i #{src} -o #{dst} --config #{config} --minify 2>&1"
    result = `#{cmd}`
    raise "Tailwind failed: #{result}" unless $?.success?
  end

  def copy_assets
    src = File.join(@site_root, 'assets')
    dst = File.join(@output_dir, 'assets')
    FileUtils.cp_r(Dir.glob("#{src}/*").reject { |f| f.end_with?('css') }, dst, remove_destination: false)
  rescue Errno::ENOENT
    nil
  end

  FAVICON_FILES = %w[favicon.ico favicon.png icon.svg apple-touch-icon.png].freeze

  def copy_favicon
    FAVICON_FILES.each do |file|
      src = File.join(@site_root, 'assets', file)
      next unless File.exist?(src)
      FileUtils.cp(src, File.join(@output_dir, file))
    end
  end

  def build_rss(lang, articles)
    t          = TRANSLATIONS[lang]
    feed_url   = "#{BASE_URL}/#{lang}/feed.xml"
    channel_url = "#{BASE_URL}/#{lang}/"

    items = articles.first(20).map do |article|
      pub_date = rss_pub_date(article)
      lines = []
      lines << "    <item>"
      lines << "      <title>#{xml_escape(article.title)}</title>"
      lines << "      <link>#{BASE_URL}#{article.url}/</link>"
      lines << "      <guid isPermaLink=\"true\">#{BASE_URL}#{article.url}/</guid>"
      lines << "      <description>#{xml_escape(article.excerpt)}</description>"
      lines << "      <pubDate>#{pub_date}</pubDate>" if pub_date
      lines << "    </item>"
      lines.join("\n")
    end

    xml = <<~XML
      <?xml version="1.0" encoding="UTF-8"?>
      <rss version="2.0" xmlns:atom="http://www.w3.org/2005/Atom">
        <channel>
          <title>#{xml_escape(t[:site_name])}</title>
          <link>#{channel_url}</link>
          <atom:link href="#{feed_url}" rel="self" type="application/rss+xml"/>
          <description>#{xml_escape(t[:site_name])}</description>
          <language>#{lang}</language>
          <lastBuildDate>#{Time.now.strftime('%a, %d %b %Y %H:%M:%S +0000')}</lastBuildDate>
      #{items.join("\n")}
        </channel>
      </rss>
    XML

    write_file("#{lang}/feed.xml", xml)
  end

  def rss_pub_date(article)
    return nil unless article.year && article.month && article.day
    Date.new(article.year, article.month, article.day).strftime('%a, %d %b %Y 00:00:00 +0000')
  rescue ArgumentError
    nil
  end

  def xml_escape(str)
    str.to_s.gsub('&', '&amp;').gsub('<', '&lt;').gsub('>', '&gt;').gsub('"', '&quot;')
  end
end
