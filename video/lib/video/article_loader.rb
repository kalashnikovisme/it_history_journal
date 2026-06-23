require "front_matter_parser"
require "date"

module Video
  class ArticleLoader
    COVER_EXTENSIONS = %w[webp png jpg jpeg].freeze

    MONTH_ABBR_MAP = {
      "jan" => 1, "feb" => 2, "mar" => 3, "apr" => 4,
      "may" => 5, "jun" => 6, "jul" => 7, "aug" => 8,
      "sep" => 9, "oct" => 10, "nov" => 11, "dec" => 12
    }.freeze

    MONTH_NAMES_EN = {
      1 => "January", 2 => "February", 3 => "March", 4 => "April",
      5 => "May", 6 => "June", 7 => "July", 8 => "August",
      9 => "September", 10 => "October", 11 => "November", 12 => "December"
    }.freeze

    MONTH_NAMES_RU = {
      1 => "Январь", 2 => "Февраль", 3 => "Март", 4 => "Апрель",
      5 => "Май", 6 => "Июнь", 7 => "Июль", 8 => "Август",
      9 => "Сентябрь", 10 => "Октябрь", 11 => "Ноябрь", 12 => "Декабрь"
    }.freeze

    MONTH_DISPLAY_RU = {
      1 => "января", 2 => "февраля", 3 => "марта", 4 => "апреля",
      5 => "мая", 6 => "июня", 7 => "июля", 8 => "августа",
      9 => "сентября", 10 => "октября", 11 => "ноября", 12 => "декабря"
    }.freeze

    def self.load(article_folder)
      new(article_folder).load
    end

    def initialize(article_folder)
      # Accept relative or absolute path; strip trailing slash
      @folder = article_folder.to_s.chomp("/")
    end

    def load
      content_file = File.join(@folder, "content.md")
      unless File.exist?(content_file)
        raise "content.md not found in #{@folder}"
      end

      raw = File.read(content_file)
      parsed = FrontMatterParser::Parser.new(:md).call(raw)
      front_matter = parsed.front_matter

      # Derive lang/month_abbr/day/slug from folder path
      # Expect: .../{lang}/{mon}/{dd}/{slug}
      parts = @folder.split("/")
      slug_dir = parts[-1]
      day_str  = parts[-2]
      mon_abbr = parts[-3]
      lang     = parts[-4]

      slug = slug_dir.tr("_", "-")
      month_num = MONTH_ABBR_MAP[mon_abbr.downcase] ||
                  raise("Unknown month abbreviation: #{mon_abbr}")
      day = day_str.to_i

      cover_path = COVER_EXTENSIONS
        .map { |ext| File.join(@folder, "cover.#{ext}") }
        .find { |p| File.exist?(p) }

      raw_date    = front_matter["date"]
      event_date  = front_matter["event_date"]
      event_year  = front_matter["event_year"] || extract_year(raw_date) || extract_year(event_date.to_s)

      year = event_year || day_str.to_i  # fallback

      month_name = month_name_for(lang, month_num)
      date_display = date_display_for(lang, day, month_num, year)
      date_month_day = date_month_day_for(lang, day, month_num)

      {
        lang:            lang,
        month_abbr:      mon_abbr.downcase,
        month_num:       month_num,
        month_name:      month_name,
        day:             day,
        year:            year.to_s,
        slug:            slug,
        slug_dir:        slug_dir,
        title:           front_matter["title"] || slug.gsub("-", " ").capitalize,
        date_display:    date_display,
        date_month_day:  date_month_day,
        content_md:      parsed.content,
        cover_path:      cover_path,
        folder:          @folder
      }
    end

    private

    def month_name_for(lang, month_num)
      if lang == "ru"
        MONTH_NAMES_RU[month_num]
      else
        MONTH_NAMES_EN[month_num]
      end
    end

    def date_display_for(lang, day, month_num, year)
      if lang == "ru"
        "#{day} #{MONTH_DISPLAY_RU[month_num]} #{year}"
      else
        "#{MONTH_NAMES_EN[month_num]} #{day}, #{year}"
      end
    end

    def date_month_day_for(lang, day, month_num)
      if lang == "ru"
        "#{day} #{MONTH_DISPLAY_RU[month_num]}"
      else
        "#{MONTH_NAMES_EN[month_num]} #{day}"
      end
    end

    def extract_year(str)
      str.to_s.match(/(\d{4})/)&.[](1)&.to_i
    end
  end
end
