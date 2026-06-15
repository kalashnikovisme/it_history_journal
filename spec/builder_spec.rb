require 'spec_helper'
require 'tmpdir'
require 'fileutils'

RSpec.describe Builder do
  let(:tmp_dir)    { Dir.mktmpdir }
  let(:output_dir) { File.join(tmp_dir, '_site') }
  let(:builder)    { Builder.new(site_root: tmp_dir, output_dir: output_dir) }

  def write_article(lang, month, day, article_name, content, with_cover: false)
    dir = File.join(tmp_dir, 'articles', lang, month, day.to_s, article_name)
    FileUtils.mkdir_p(dir)
    File.write(File.join(dir, 'content.md'), content)
    File.write(File.join(dir, 'cover.png'), "\x89PNG") if with_cover
  end

  def write_asset
    dir = File.join(tmp_dir, 'assets', 'css')
    FileUtils.mkdir_p(dir)
    File.write(File.join(dir, 'input.css'), '@tailwind base;')
    File.write(File.join(tmp_dir, 'assets', 'favicon.png'), "\x89PNG")
    File.write(File.join(tmp_dir, 'assets', 'favicon.ico'), "ICO")
    File.write(File.join(tmp_dir, 'assets', 'icon.svg'), '<svg/>')
    File.write(File.join(tmp_dir, 'assets', 'apple-touch-icon.png'), "\x89PNG")
  end

  def jsonld_for(relative_path)
    content = File.read(File.join(output_dir, relative_path))
    match = content.match(%r{<script type='application/ld\+json'>\s*(.*?)\s*</script>}m)
    raise "No JSON-LD found in #{relative_path}" unless match

    JSON.parse(match[1])
  end

  before do
    write_article('en', 'may', 19, 'james_gosling_was_born', <<~MD)
      ---
      title: "May 19, 1955 — James Gosling Was Born"
      date: "May 19, 1955"
      excerpt: "James Gosling created Java."
      popular: true
      ---

      James Gosling created Java.
    MD

    write_article('en', 'may', 18, 'facebook_ipo', <<~MD)
      ---
      title: "May 18, 2012 — Facebook IPO"
      date: "May 18, 2012"
      excerpt: "Facebook went public."
      ---

      Facebook went public.
    MD

    write_article('ru', 'may', 19, 'james_gosling_was_born', <<~MD)
      ---
      title: "19 мая 1955 — Родился Джеймс Гослинг"
      date: "19 мая 1955"
      excerpt: "Джеймс Гослинг создал Java."
      ---

      Джеймс Гослинг создал Java.
    MD

    tailwind_config = File.join(tmp_dir, 'tailwind.config.js')
    File.write(tailwind_config, 'module.exports = { content: [], theme: {}, plugins: [] }')

    write_asset

    allow(builder).to receive(:compile_css)
  end

  after { FileUtils.rm_rf(tmp_dir) }

  describe '#build' do
    before { builder.build }

    it 'creates the root redirect page' do
      expect(File.exist?(File.join(output_dir, 'index.html'))).to be true
    end

    it 'redirects to /en/ by default in root page' do
      content = File.read(File.join(output_dir, 'index.html'))
      expect(content).to include('/en/')
    end

    it 'redirects to /ru/ for Russian browser language' do
      content = File.read(File.join(output_dir, 'index.html'))
      expect(content).to include('/ru/')
    end

    it 'creates the English index page' do
      expect(File.exist?(File.join(output_dir, 'en', 'index.html'))).to be true
    end

    it 'creates the Russian index page' do
      expect(File.exist?(File.join(output_dir, 'ru', 'index.html'))).to be true
    end

    it 'creates the English article page with directory-based URL' do
      path = File.join(output_dir, 'en', 'may', '19', 'james-gosling-was-born', 'index.html')
      expect(File.exist?(path)).to be true
    end

    it 'creates the Russian article page' do
      path = File.join(output_dir, 'ru', 'may', '19', 'james-gosling-was-born', 'index.html')
      expect(File.exist?(path)).to be true
    end

    it 'creates the English calendar page' do
      expect(File.exist?(File.join(output_dir, 'en', 'calendar', 'index.html'))).to be true
    end

    it 'creates the Russian calendar page' do
      expect(File.exist?(File.join(output_dir, 'ru', 'calendar', 'index.html'))).to be true
    end

    it 'renders the article title on the article page' do
      content = File.read(File.join(output_dir, 'en', 'may', '19', 'james-gosling-was-born', 'index.html'))
      expect(content).to include('James Gosling Was Born')
    end

    it 'renders the article content on the article page' do
      content = File.read(File.join(output_dir, 'en', 'may', '19', 'james-gosling-was-born', 'index.html'))
      expect(content).to include('James Gosling created Java.')
    end

    it 'renders article links in the English index' do
      content = File.read(File.join(output_dir, 'en', 'index.html'))
      expect(content).to include('/en/may/19/james-gosling-was-born')
    end

    it 'uses Russian translations on the Russian index' do
      content = File.read(File.join(output_dir, 'ru', 'index.html'))
      expect(content).to include('Последние записи').or include('Последняя запись')
    end

    it 'includes a language switch link on the English index' do
      content = File.read(File.join(output_dir, 'en', 'index.html'))
      expect(content).to include('/ru/')
    end

    it 'includes calendar navigation link' do
      content = File.read(File.join(output_dir, 'en', 'index.html'))
      expect(content).to include('/en/calendar/')
    end

    it 'creates the English articles index page' do
      expect(File.exist?(File.join(output_dir, 'en', 'articles', 'index.html'))).to be true
    end

    it 'creates the Russian articles index page' do
      expect(File.exist?(File.join(output_dir, 'ru', 'articles', 'index.html'))).to be true
    end

    it 'renders article titles on the articles page' do
      content = File.read(File.join(output_dir, 'en', 'articles', 'index.html'))
      expect(content).to include('James Gosling Was Born')
    end

    it 'includes a link to the articles page on the index' do
      content = File.read(File.join(output_dir, 'en', 'index.html'))
      expect(content).to include('/en/articles/')
    end

    it 'sets the correct lang attribute on the html element' do
      content = File.read(File.join(output_dir, 'en', 'index.html'))
      expect(content).to include('lang="en"').or include("lang='en'")
    end

    it 'copies favicon files to the site root' do
      expect(File.exist?(File.join(output_dir, 'favicon.ico'))).to be true
      expect(File.exist?(File.join(output_dir, 'icon.svg'))).to be true
      expect(File.exist?(File.join(output_dir, 'apple-touch-icon.png'))).to be true
    end

    it 'creates robots.txt with a sitemap reference' do
      content = File.read(File.join(output_dir, 'robots.txt'))

      expect(content).to include('User-agent: *')
      expect(content).to include('Allow: /')
      expect(content).to include('Sitemap: https://history.purple-magic.com/sitemap.xml')
    end

    it 'creates sitemap.xml with all article URLs' do
      content = File.read(File.join(output_dir, 'sitemap.xml'))

      expect(content).to include('<?xml version="1.0" encoding="UTF-8"?>')
      expect(content).to include('<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">')
      expect(content).to include('<loc>https://history.purple-magic.com/en/may/18/facebook-ipo/</loc>')
      expect(content).to include('<loc>https://history.purple-magic.com/en/may/19/james-gosling-was-born/</loc>')
      expect(content).to include('<loc>https://history.purple-magic.com/ru/may/19/james-gosling-was-born/</loc>')
    end

    it 'includes favicon links in the page head' do
      content = File.read(File.join(output_dir, 'en', 'index.html'))
      expect(content).to include("href='/favicon.ico'")
      expect(content).to include("href='/icon.svg'")
      expect(content).to include("href='/apple-touch-icon.png' rel='apple-touch-icon'")
    end

    it 'adds WebSite schema.org JSON-LD to the root redirect page' do
      jsonld = jsonld_for('index.html')

      expect(jsonld['@context']).to eq('https://schema.org')
      expect(jsonld['@type']).to eq('WebSite')
      expect(jsonld['url']).to eq('https://history.purple-magic.com')
      expect(jsonld['inLanguage']).to eq(%w[en ru])
    end

    it 'adds WebPage schema.org JSON-LD to language home pages' do
      jsonld = jsonld_for('en/index.html')

      expect(jsonld['@type']).to eq('WebPage')
      expect(jsonld['url']).to eq('https://history.purple-magic.com/en/')
      expect(jsonld['inLanguage']).to eq('en')
      expect(jsonld['mainEntity']['@type']).to eq('ItemList')
    end

    it 'adds CollectionPage schema.org JSON-LD to article index pages' do
      jsonld = jsonld_for('en/articles/index.html')

      expect(jsonld['@type']).to eq('CollectionPage')
      expect(jsonld['url']).to eq('https://history.purple-magic.com/en/articles/')
      expect(jsonld['mainEntity']['itemListElement'].first['@type']).to eq('ListItem')
    end

    it 'adds CollectionPage schema.org JSON-LD to calendar pages' do
      jsonld = jsonld_for('en/calendar/index.html')

      expect(jsonld['@type']).to eq('CollectionPage')
      expect(jsonld['url']).to eq('https://history.purple-magic.com/en/calendar/')
      expect(jsonld['mainEntity']['@type']).to eq('ItemList')
    end

    it 'adds CollectionPage schema.org JSON-LD to year pages' do
      jsonld = jsonld_for('en/1955/index.html')

      expect(jsonld['@type']).to eq('CollectionPage')
      expect(jsonld['url']).to eq('https://history.purple-magic.com/en/1955/')
      expect(jsonld['mainEntity']['itemListElement'].first['name']).to include('James Gosling')
    end

    context 'when article has a cover image' do
      before do
        write_article('en', 'may', 17, 'minecraft', <<~MD, with_cover: true)
          ---
          title: "May 17, 2009 — Minecraft"
          excerpt: "Minecraft released."
          ---
          Minecraft released.
        MD
        builder.build
      end

      it 'copies cover.png to the article output directory' do
        path = File.join(output_dir, 'en', 'may', '17', 'minecraft', 'cover.png')
        expect(File.exist?(path)).to be true
      end

      it 'includes the cover image tag in the article HTML' do
        content = File.read(File.join(output_dir, 'en', 'may', '17', 'minecraft', 'index.html'))
        expect(content).to include('cover.png')
      end
    end

    context 'open graph meta tags on article pages' do
      let(:article_html) do
        File.read(File.join(output_dir, 'en', 'may', '19', 'james-gosling-was-born', 'index.html'))
      end

      it 'includes og:type article' do
        expect(article_html).to include("property='og:type'").and include("content='article'")
      end

      it 'includes og:title with the article title' do
        expect(article_html).to include("property='og:title'")
          .and include('James Gosling Was Born')
      end

      it 'includes og:description with the article excerpt' do
        expect(article_html).to include("property='og:description'")
          .and include('James Gosling created Java.')
      end

      it 'includes og:url with the absolute article URL' do
        expect(article_html).to include("property='og:url'")
          .and include('https://history.purple-magic.com/en/may/19/james-gosling-was-born/')
      end

      it 'includes twitter:card meta tag' do
        expect(article_html).to include("name='twitter:card'")
      end

      it 'does not include og:image when article has no cover' do
        expect(article_html).not_to include("property='og:image'")
      end

      it 'does not render og tags on non-article pages' do
        index_html = File.read(File.join(output_dir, 'en', 'index.html'))
        expect(index_html).not_to include("property='og:type'")
      end

      context 'when article has a cover image' do
        before do
          write_article('en', 'may', 16, 'tetris', <<~MD, with_cover: true)
            ---
            title: "May 16, 1984 — Tetris"
            excerpt: "Tetris was created."
            ---
            Tetris was created.
          MD
          builder.build
        end

        it 'includes og:image with the absolute cover URL' do
          html = File.read(File.join(output_dir, 'en', 'may', '16', 'tetris', 'index.html'))
          expect(html).to include("property='og:image'")
            .and include('https://history.purple-magic.com/en/may/16/tetris/cover.png')
        end

        it 'sets twitter:card to summary_large_image' do
          html = File.read(File.join(output_dir, 'en', 'may', '16', 'tetris', 'index.html'))
          expect(html).to include("content='summary_large_image'")
        end
      end
    end
  end

  describe 'year pages' do
    before { builder.build }

    it 'creates a year page for each distinct article year' do
      expect(File.exist?(File.join(output_dir, 'en', '1955', 'index.html'))).to be true
      expect(File.exist?(File.join(output_dir, 'en', '2012', 'index.html'))).to be true
    end

    it 'creates year pages for Russian articles' do
      expect(File.exist?(File.join(output_dir, 'ru', '1955', 'index.html'))).to be true
    end

    it 'renders the year as a heading on the year page' do
      content = File.read(File.join(output_dir, 'en', '1955', 'index.html'))
      expect(content).to include('1955')
    end

    it 'lists articles on the year page in chronological order' do
      content = File.read(File.join(output_dir, 'en', '1955', 'index.html'))
      expect(content).to include('James Gosling Was Born')
    end

    it 'does not include articles from other years on a year page' do
      content = File.read(File.join(output_dir, 'en', '1955', 'index.html'))
      expect(content).not_to include('Facebook IPO')
    end

    it 'includes year links on the index page' do
      content = File.read(File.join(output_dir, 'en', 'index.html'))
      expect(content).to include('/en/1955/')
      expect(content).to include('/en/2012/')
    end

    it 'shows the browse by year heading on the index page' do
      content = File.read(File.join(output_dir, 'en', 'index.html'))
      expect(content).to include('Browse by year')
    end
  end

  describe 'articles pagination' do
    let(:builder) { Builder.new(site_root: tmp_dir, output_dir: output_dir, articles_per_page: 1) }

    before { builder.build }

    it 'creates page 1 at the articles root path' do
      expect(File.exist?(File.join(output_dir, 'en', 'articles', 'index.html'))).to be true
    end

    it 'creates page 2 when articles exceed one page' do
      expect(File.exist?(File.join(output_dir, 'en', 'articles', '2', 'index.html'))).to be true
    end

    it 'does not create a page beyond the total count' do
      expect(File.exist?(File.join(output_dir, 'en', 'articles', '3', 'index.html'))).to be false
    end

    it 'includes pagination links on page 1' do
      content = File.read(File.join(output_dir, 'en', 'articles', 'index.html'))
      expect(content).to include('/en/articles/2/')
    end

    it 'includes a back link to page 1 on page 2' do
      content = File.read(File.join(output_dir, 'en', 'articles', '2', 'index.html'))
      expect(content).to include('/en/articles/')
    end
  end

  describe 'RSS feeds' do
    before { builder.build }

    it 'creates an English RSS feed' do
      expect(File.exist?(File.join(output_dir, 'en', 'feed.xml'))).to be true
    end

    it 'creates a Russian RSS feed' do
      expect(File.exist?(File.join(output_dir, 'ru', 'feed.xml'))).to be true
    end

    it 'is a valid RSS 2.0 document' do
      content = File.read(File.join(output_dir, 'en', 'feed.xml'))
      expect(content).to include('<?xml version="1.0" encoding="UTF-8"?>')
      expect(content).to include('<rss version="2.0"')
      expect(content).to include('</rss>')
    end

    it 'includes article titles in the English feed' do
      content = File.read(File.join(output_dir, 'en', 'feed.xml'))
      expect(content).to include('James Gosling Was Born')
    end

    it 'includes absolute article URLs in the feed' do
      content = File.read(File.join(output_dir, 'en', 'feed.xml'))
      expect(content).to include('https://history.purple-magic.com/en/may/19/james-gosling-was-born/')
    end

    it 'includes the atom:link self-reference' do
      content = File.read(File.join(output_dir, 'en', 'feed.xml'))
      expect(content).to include('https://history.purple-magic.com/en/feed.xml')
    end

    it 'includes pubDate for articles with known dates' do
      content = File.read(File.join(output_dir, 'en', 'feed.xml'))
      expect(content).to include('<pubDate>')
      expect(content).to include('1955')
    end

    it 'includes article excerpts as descriptions' do
      content = File.read(File.join(output_dir, 'en', 'feed.xml'))
      expect(content).to include('James Gosling created Java.')
    end
  end

  describe 'today article on index' do
    context 'when an article matches today month/day (May 18)' do
      before do
        allow(Date).to receive(:today).and_return(Date.new(2012, 5, 18))
        builder.build
      end

      it 'renders the today candidate with the correct data-today-key' do
        content = File.read(File.join(output_dir, 'en', 'index.html'))
        expect(content).to include("data-today-key='5-18'")
        expect(content).to include('Facebook IPO')
      end

      it 'renders the tomorrow candidate (May 19) as second candidate' do
        content = File.read(File.join(output_dir, 'en', 'index.html'))
        expect(content).to include("data-today-key='5-19'")
        expect(content).to include('James Gosling Was Born')
      end

      it 'includes On this day label and no Latest post fallback' do
        content = File.read(File.join(output_dir, 'en', 'index.html'))
        expect(content).to include('On this day')
        expect(content).not_to include('Latest post')
      end

      it 'renders candidate sections before recent articles' do
        content = File.read(File.join(output_dir, 'en', 'index.html'))
        today_key_pos = content.index('data-today-key')
        recent_pos    = content.index('Recent posts')
        expect(today_key_pos).to be < recent_pos
      end

      it 'includes both candidates in recent list with data-recent-key wrappers' do
        content = File.read(File.join(output_dir, 'en', 'index.html'))
        expect(content).to include("data-recent-key='5-18'")
        expect(content).to include("data-recent-key='5-19'")
      end
    end

    context 'when an article matches tomorrow month/day only (May 19)' do
      before do
        # today = May 19 means tomorrow = May 20 (no article), today = May 19 matches Gosling
        allow(Date).to receive(:today).and_return(Date.new(2012, 5, 19))
        builder.build
      end

      it 'renders the today candidate (May 19) with correct key' do
        content = File.read(File.join(output_dir, 'en', 'index.html'))
        expect(content).to include("data-today-key='5-19'")
      end

      it 'does not render a Latest post fallback' do
        content = File.read(File.join(output_dir, 'en', 'index.html'))
        expect(content).not_to include('Latest post')
      end
    end

    context 'when no article matches today or tomorrow' do
      before do
        allow(Date).to receive(:today).and_return(Date.new(2012, 5, 20))
        builder.build
      end

      it 'renders no data-today-key candidate sections' do
        content = File.read(File.join(output_dir, 'en', 'index.html'))
        expect(content).not_to match(/data-today-key='[\d-]+'/)
      end

      it 'shows the fallback Latest post section before recent articles' do
        content = File.read(File.join(output_dir, 'en', 'index.html'))
        fallback_pos = content.index('Latest post')
        gosling_pos  = content.index('James Gosling Was Born')
        expect(fallback_pos).to be < gosling_pos
      end
    end
  end

  describe '#load_articles' do
    it 'loads articles from the articles directory' do
      articles = builder.load_articles
      expect(articles.length).to eq(3)
    end

    it 'returns Article instances' do
      articles = builder.load_articles
      expect(articles).to all(be_an(Article))
    end
  end
end
