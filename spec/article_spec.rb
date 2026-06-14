require 'spec_helper'
require 'tmpdir'
require 'fileutils'

RSpec.describe Article do
  let(:tmp_dir)    { Dir.mktmpdir }
  let(:article_dir) { File.join(tmp_dir, 'articles', 'en', 'may', '19', 'james_gosling_was_born') }
  let(:article_file) { File.join(article_dir, 'content.md') }

  before do
    FileUtils.mkdir_p(article_dir)
    File.write(article_file, <<~MD)
      ---
      title: "May 19, 1955 — James Gosling Was Born"
      date: "May 19, 1955"
      excerpt: "James Gosling is considered the main creator of Java."
      popular: true
      author: "Pasha Kalashnikov"
      ---

      James Gosling created Java.

      It became one of the most popular languages.
    MD
  end

  after { FileUtils.rm_rf(tmp_dir) }

  subject(:article) { Article.parse(article_file, site_root: tmp_dir) }

  describe '.parse' do
    it 'reads the title from frontmatter' do
      expect(article.title).to eq("May 19, 1955 — James Gosling Was Born")
    end

    it 'reads the date from frontmatter' do
      expect(article.date).to eq("May 19, 1955")
    end

    it 'reads the excerpt from frontmatter' do
      expect(article.excerpt).to eq("James Gosling is considered the main creator of Java.")
    end

    it 'reads the popular flag' do
      expect(article.popular).to be true
    end

    it 'reads the author from frontmatter' do
      expect(article.author).to eq('Pasha Kalashnikov')
    end

    it 'detects the language from path' do
      expect(article.lang).to eq('en')
    end

    it 'detects the date_path from path' do
      expect(article.date_path).to eq('may/19')
    end

    it 'derives the slug from the article directory name' do
      expect(article.slug).to eq('james-gosling-was-born')
    end

    it 'parses the month number' do
      expect(article.month).to eq(5)
    end

    it 'parses the day number' do
      expect(article.day).to eq(19)
    end

    it 'parses the year from the date field' do
      expect(article.year).to eq(1955)
    end

    it 'returns nil year when date is absent' do
      File.write(article_file, "---\ntitle: No Date\n---\nContent.")
      expect(Article.parse(article_file, site_root: tmp_dir).year).to be_nil
    end

    it 'extracts content_md as the body without frontmatter' do
      expect(article.content_md).to include('James Gosling created Java.')
      expect(article.content_md).not_to include('title:')
    end

    it 'sets cover_path to nil when cover.png is absent' do
      expect(article.cover_path).to be_nil
    end

    it 'sets cover_path when cover.png is present' do
      File.write(File.join(article_dir, 'cover.png'), 'PNG')
      expect(article.cover_path).to eq(File.join(article_dir, 'cover.png'))
    end
  end

  describe '#cover?' do
    it 'returns false when cover.png is absent' do
      expect(article.cover?).to be false
    end

    it 'returns true when cover.png is present' do
      File.write(File.join(article_dir, 'cover.png'), 'PNG')
      expect(article.cover?).to be true
    end
  end

  describe '#cover_url' do
    it 'returns the cover URL using the actual cover filename' do
      File.write(File.join(article_dir, 'cover.png'), 'PNG')
      expect(article.cover_url).to eq('/en/may/19/james-gosling-was-born/cover.png')
    end

    it 'uses the webp filename when cover.webp is present' do
      File.write(File.join(article_dir, 'cover.webp'), 'WEBP')
      expect(article.cover_url).to eq('/en/may/19/james-gosling-was-born/cover.webp')
    end

    it 'prefers webp over png when both exist' do
      File.write(File.join(article_dir, 'cover.webp'), 'WEBP')
      File.write(File.join(article_dir, 'cover.png'), 'PNG')
      expect(article.cover_url).to eq('/en/may/19/james-gosling-was-born/cover.webp')
    end
  end

  describe '#url' do
    it 'builds the correct URL' do
      expect(article.url).to eq('/en/may/19/james-gosling-was-born')
    end
  end

  describe '#date_label' do
    it 'returns a human-readable month day' do
      expect(article.date_label).to eq('May 19')
    end
  end

  describe '#content_html' do
    it 'renders markdown to HTML' do
      expect(article.content_html).to include('<p>')
      expect(article.content_html).to include('James Gosling created Java.')
    end
  end

  describe '.extract_excerpt' do
    it 'returns first paragraph when no frontmatter excerpt' do
      content = "First paragraph text.\n\nSecond paragraph."
      result = Article.extract_excerpt(content)
      expect(result).to eq('First paragraph text.')
    end

    it 'strips markdown headings' do
      content = "# Heading\n\nActual paragraph."
      result = Article.extract_excerpt(content)
      expect(result).not_to include('#')
      expect(result).to include('Actual paragraph.')
    end

    it 'truncates long paragraphs' do
      content = 'A' * 300
      result = Article.extract_excerpt(content, max_length: 200)
      expect(result.length).to be <= 204
      expect(result).to end_with('...')
    end
  end

  context 'without frontmatter excerpt' do
    before do
      File.write(article_file, <<~MD)
        ---
        title: "Test Article"
        ---

        This is the first paragraph and it should become the excerpt.

        Second paragraph here.
      MD
    end

    it 'auto-extracts excerpt from content' do
      expect(article.excerpt).to eq('This is the first paragraph and it should become the excerpt.')
    end
  end
end
