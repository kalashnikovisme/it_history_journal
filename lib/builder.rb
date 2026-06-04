require 'haml'
require 'fileutils'
require 'date'
require_relative 'article'
require_relative 'render_scope'

class Builder
  TEMPLATES_DIR = File.expand_path('../../templates', __FILE__)
  LANGUAGES     = %w[en ru].freeze

  TRANSLATIONS = {
    'en' => {
      site_name:     'IT History Journal',
      latest_post:   'Latest post',
      recent_posts:  'Recent posts',
      popular_posts: 'Popular posts',
      related_posts: 'Related posts',
      calendar:      'Calendar',
      home:          'Home',
      read_more:     'Read more',
      lang_switch:   'RU',
      months:        %w[January February March April May June
                        July August September October November December]
    },
    'ru' => {
      site_name:     'IT History Journal',
      latest_post:   'Последняя запись',
      recent_posts:  'Последние записи',
      popular_posts: 'Популярные записи',
      related_posts: 'Похожие статьи',
      calendar:      'Календарь',
      home:          'Главная',
      read_more:     'Читать далее',
      lang_switch:   'EN',
      months:        %w[Январь Февраль Март Апрель Май Июнь
                        Июль Август Сентябрь Октябрь Ноябрь Декабрь]
    }
  }.freeze

  def initialize(site_root: '.', output_dir: '_site')
    @site_root  = File.expand_path(site_root)
    @output_dir = File.expand_path(output_dir)
    @scope      = RenderScope.new
  end

  def build
    FileUtils.rm_rf(@output_dir)
    FileUtils.mkdir_p(@output_dir)

    all_articles = load_articles
    build_redirect
    compile_css
    build_all_html(all_articles)
    copy_assets
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
      articles.each { |article| build_article(article, articles) }
    end
  end

  def build_redirect
    html = render_template('redirect', {})
    write_file('index.html', html)
  end

  def build_index(lang, articles)
    t       = TRANSLATIONS[lang]
    latest  = articles.first
    recent  = articles.first(10)
    popular = articles.select(&:popular).first(10)
    popular = recent.first(6) if popular.empty?

    today = Date.today
    days_with_articles = articles.each_with_object({}) do |a, h|
      h[[a.month, a.day]] = a.url
    end

    inner = render_template('index', {
      lang:               lang,
      t:                  t,
      latest:             latest,
      recent:             recent,
      popular:            popular,
      days_with_articles: days_with_articles,
      current_month:      today.month,
      current_year:       today.year,
      current_day:        today.day
    })
    html = wrap_layout(lang, t[:site_name], inner)
    write_file("#{lang}/index.html", html)
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
    html  = wrap_layout(article.lang, title, inner)
    write_file("#{article.lang}/#{article.date_path}/#{article.slug}/index.html", html)

    if article.cover?
      dst = File.join(@output_dir, article.lang, article.date_path, article.slug, File.basename(article.cover_path))
      FileUtils.cp(article.cover_path, dst)
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

  def wrap_layout(lang, title, content)
    t = TRANSLATIONS[lang]
    render_template('layout', {
      lang:    lang,
      title:   title,
      t:       t,
      content: content,
      year:    Date.today.year
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
end
