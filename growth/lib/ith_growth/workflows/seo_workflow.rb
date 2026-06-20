require "json"
require "date"
require "ith_growth/article/parser"
require "ith_growth/article/patcher"
require "ith_growth/analytics/ga_client"
require "ith_growth/analytics/search_console_client"
require "ith_growth/workflows/base_workflow"

module IthGrowth
  module Workflows
    class SeoWorkflow < BaseWorkflow
      def run(path, website_repo: nil)
        article = Article::Parser.new.parse(path)
        article_rel_dir = article_relative_dir(article.path)
        seo_writer = Outputs::Writer.new(base_dir: config.seo_output_dir)
        date = Date.today.to_s

        with_logging(name: "seo", input_files: [path, website_repo].compact) do
          history = load_history(article_rel_dir)
          analytics_data = fetch_analytics_data(article.path)
          analytics_markdown = format_analytics_markdown(analytics_data)

          append_metrics(article_rel_dir, seo_writer, analytics_data, date)

          markdown = prompt_runner.run(
            template: "seo",
            variables: common_variables(article).merge(
              website_repo: website_repo,
              seo_history: history_block(history),
              analytics_data: analytics_markdown || "_Not configured or no data yet._"
            ),
            model: config.ai_model
          )

          patch = extract_patch(markdown)
          suggestions = strip_patch_block(markdown)
          report = build_report(date, analytics_markdown, suggestions)

          schema = {
            "@context": "https://schema.org",
            "@type": "Article",
            "headline": patch["title"] || article.title,
            "url": "#{config.site_url}#{article_page_path(article.path)}/",
            "description": patch["excerpt"] || ""
          }

          outputs = [
            seo_writer.write("articles/#{article_rel_dir}/seo-#{date}.md", report),
            seo_writer.write_json("articles/#{article_rel_dir}/schema.json", schema)
          ]

          Article::Patcher.new.apply(path, patch) if patch.any?

          outputs
        end
      end

      def load_metrics(article_rel_dir)
        path = File.join(config.seo_output_dir, "articles", article_rel_dir, "metrics.json")
        return [] unless File.exist?(path)
        JSON.parse(File.read(path))
      rescue JSON::ParserError
        []
      end

      private

      def load_history(article_rel_dir)
        seo_dir = File.join(config.seo_output_dir, "articles", article_rel_dir)
        return [] unless Dir.exist?(seo_dir)
        Dir.glob(File.join(seo_dir, "seo-*.md")).sort.map { |f| File.read(f) }
      end

      def history_block(history)
        return "_No previous SEO reports for this article._" if history.empty?
        history.join("\n\n---\n\n")
      end

      def fetch_analytics_data(article_path)
        data = {}

        if config.gsc_site_url && config.gsc_credentials_path
          page_url = "#{config.gsc_site_url}#{article_page_path(article_path)}"
          gsc = Analytics::SearchConsoleClient.new(
            site_url: config.gsc_site_url,
            credentials_path: config.gsc_credentials_path
          )
          rows = gsc.page_queries(page_url: page_url)
          data[:gsc] = rows.map { |r| r.transform_keys(&:to_s) }
        end

        if config.ga4_property_id && config.ga4_credentials_path
          ga = Analytics::GaClient.new(
            property_id: config.ga4_property_id,
            credentials_path: config.ga4_credentials_path
          )
          stats = ga.page_stats(page_path: article_page_path(article_path))
          data[:ga4] = stats if stats
        end

        data
      rescue => e
        { error: e.message }
      end

      def format_analytics_markdown(data)
        return "_(Analytics fetch failed: #{data[:error]})_" if data[:error]

        sections = []

        if data[:gsc]
          gsc = Analytics::SearchConsoleClient.new(site_url: "", credentials_path: "")
          rows = data[:gsc].map { |r| r.transform_keys(&:to_sym) }
          sections << "### Google Search Console — last 28 days\n\n#{gsc.format_as_markdown(rows)}"
        end

        if data[:ga4]
          s = data[:ga4]
          sections << "### Google Analytics — last 28 days\n\n" \
            "Views: #{s[:views]} | Bounce Rate: #{(s[:bounce_rate] * 100).round(1)}% | Avg Duration: #{s[:avg_duration].round}s"
        end

        sections.empty? ? nil : sections.join("\n\n")
      end

      def append_metrics(article_rel_dir, seo_writer, data, date)
        return if data.empty? || data[:error]

        metrics_path = File.join(config.seo_output_dir, "articles", article_rel_dir, "metrics.json")
        existing = File.exist?(metrics_path) ? JSON.parse(File.read(metrics_path)) : []

        entry = { "date" => date }
        entry["ga4"] = {
          "views" => data[:ga4][:views],
          "bounce_rate" => data[:ga4][:bounce_rate],
          "avg_duration" => data[:ga4][:avg_duration]
        } if data[:ga4]
        entry["gsc"] = data[:gsc].map { |r| r.transform_keys(&:to_s) } if data[:gsc]

        existing.reject! { |e| e["date"] == date }
        existing << entry

        seo_writer.write_json("articles/#{article_rel_dir}/metrics.json", existing)
      end

      def build_report(date, analytics_markdown, suggestions)
        parts = ["# SEO Report — #{date}"]
        parts << "## Analytics\n\n#{analytics_markdown}" if analytics_markdown
        parts << "## Suggestions\n\n#{suggestions}"
        parts.join("\n\n")
      end

      def extract_patch(markdown)
        blocks = markdown.scan(/```(?:seo_patch|json)?\n(.*?)\n```/m).map(&:first)
        blocks.reverse_each do |json|
          data = JSON.parse(json).slice("title", "excerpt")
          return data if data.any?
        rescue JSON::ParserError
          next
        end
        {}
      end

      def strip_patch_block(markdown)
        markdown.gsub(/```seo_patch\n.*?\n```\n?/m, "").strip
      end
    end
  end
end
