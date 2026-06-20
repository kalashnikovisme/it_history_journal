require "fileutils"
require "thor"
require "ith_growth/config"
require "ith_growth/logger"
require "ith_growth/ai/fake_client"
require "ith_growth/ai/openai_client"
require "ith_growth/ai/anthropic_client"
require "ith_growth/ai/prompt_runner"
require "ith_growth/article/parser"
require "ith_growth/outputs/writer"
require "ith_growth/workflows/article_analysis_workflow"
require "ith_growth/workflows/distribution_workflow"
require "ith_growth/workflows/seo_workflow"
require "ith_growth/workflows/conversion_workflow"
require "ith_growth/workflows/daily_workflow"
require "ith_growth/workflows/weekly_workflow"
require "ith_growth/analytics/ga_client"
require "ith_growth/analytics/search_console_client"

module IthGrowth
  class ArticleCLI < Thor
    desc "analyze PATH", "Analyze an article"
    def analyze(path)
      IthGrowth::CLI.context.workflow(:analysis).run(path).each { |file| say file }
    end

    desc "promote PATH", "Generate analysis, SEO, and conversion drafts"
    def promote(path)
      ctx = IthGrowth::CLI.context
      ctx.workflow(:analysis).run(path)
      ctx.workflow(:seo).run(path)
      ctx.workflow(:conversion).run(path)
    end

    desc "seo PATH", "Show SEO progress and generate a new SEO report for an article"
    def seo(path)
      ctx = IthGrowth::CLI.context
      workflow = ctx.workflow(:seo)
      rel_dir = article_rel_dir(path, ctx.config)
      print_seo_progress(rel_dir, workflow.load_metrics(rel_dir))
      workflow.run(path)
    end

    no_commands do
      def article_rel_dir(article_path, config)
        content_dir = config.content_dir&.chomp("/") || "articles"
        rel = article_path.delete_prefix("#{content_dir}/")
        File.dirname(rel)
      end

      def print_seo_progress(article_rel_dir, metrics)
        bar = "━" * 60
        say bar.cyan
        say "  SEO Progress: #{article_rel_dir}".cyan.bold
        say bar.cyan

        if metrics.empty?
          say "  No history yet — this is the first run.\n".light_black
          return
        end

        say ""
        say format("  %-12s  %6s  %7s  %9s  %7s  %8s",
          "Date", "Views", "Bounce", "Avg Time", "Clicks", "Avg Pos").bold

        metrics.each_with_index do |entry, idx|
          prev = idx > 0 ? metrics[idx - 1] : nil
          ga4  = entry["ga4"]
          gsc  = entry["gsc"] || []

          total_clicks = gsc.sum { |r| r["clicks"].to_i }
          avg_pos      = gsc.empty? ? nil : (gsc.sum { |r| r["position"].to_f } / gsc.size).round(1)
          avg_duration = ga4 ? format_duration(ga4["avg_duration"].to_f) : "-"
          bounce       = ga4 ? "#{(ga4["bounce_rate"].to_f * 100).round(1)}%" : "-"
          views        = ga4 ? ga4["views"].to_i : "-"

          say format("  %-12s  %6s  %7s  %9s  %7s  %8s  %s",
            entry["date"], views, bounce, avg_duration,
            total_clicks, avg_pos || "-", trend_indicator(entry, prev))
        end

        latest_gsc = metrics.last["gsc"] || []
        unless latest_gsc.empty?
          say ""
          say "  Top queries (#{metrics.last["date"]}):".bold
          latest_gsc.first(5).each do |r|
            say format("    %-40s  %3d clicks   pos %s",
              r["dimension"] || r["query"] || "-",
              r["clicks"].to_i,
              r["position"].to_f.round(1))
          end
        end

        say ""
        say bar.cyan
        say ""
      end

      def trend_indicator(current, prev)
        return "" unless prev
        signals = []
        if current["ga4"] && prev["ga4"]
          signals << (current["ga4"]["views"].to_i >= prev["ga4"]["views"].to_i ? "↑views" : "↓views")
        end
        curr_pos = avg_gsc_position(current["gsc"])
        prev_pos = avg_gsc_position(prev["gsc"])
        signals << (curr_pos < prev_pos ? "↑rank" : "↓rank") if curr_pos && prev_pos
        signals.join(" ").green
      end

      def avg_gsc_position(gsc)
        return nil if gsc.nil? || gsc.empty?
        (gsc.sum { |r| r["position"].to_f } / gsc.size).round(1)
      end

      def format_duration(seconds)
        m = (seconds / 60).floor
        s = (seconds % 60).round
        "#{m}:#{s.to_s.rjust(2, "0")}"
      end
    end
  end

  class CLI < Thor
    desc "init", "Create config/config.yml from config.example.yml"
    def init
      FileUtils.cp("config/config.example.yml", "config/config.yml") unless File.exist?("config/config.yml")
      say "Ready: config/config.yml"
    end

    desc "articles SUBCOMMAND", "Article commands"
    subcommand "articles", Class.new(Thor) {
      desc "list", "List Markdown articles in the configured content directory"
      def list
        config = IthGrowth::Config.load
        dir = config.content_dir
        if dir.nil? || !Dir.exist?(dir)
          say "Content directory not found: #{dir.inspect}"
          return
        end
        Dir.glob(File.join(dir, "**/*.md")).sort.each { |path| say path }
      end
    }

    desc "article SUBCOMMAND", "Run article workflows"
    subcommand "article", ArticleCLI

    desc "seo SUBCOMMAND", "SEO commands"
    subcommand "seo", Class.new(Thor) {
      desc "suggest PATH", "Generate SEO suggestions"
      option :website_repo, type: :string
      def suggest(path)
        IthGrowth::CLI.context.workflow(:seo).run(path, website_repo: options[:website_repo]).each { |file| say file }
      end
    }

    desc "distribution SUBCOMMAND", "Distribution commands"
    subcommand "distribution", Class.new(Thor) {
      desc "generate PATH", "Generate distribution drafts"
      def generate(path)
        IthGrowth::CLI.context.workflow(:distribution).run(path).each { |file| say file }
      end
    }

    desc "conversion PATH", "Generate Patreon/Boosty conversion suggestions"
    def conversion(path)
      self.class.context.workflow(:conversion).run(path).each { |file| say file }
    end

    desc "workflow SUBCOMMAND", "Run named workflows"
    subcommand "workflow", Class.new(Thor) {
      desc "run NAME", "Run daily or weekly workflow"
      map "run" => :run_workflow
      def run_workflow(name)
        workflow = IthGrowth::CLI.context.workflow(name.to_sym)
        workflow.run.each { |file| say file }
      end
    }

    desc "analytics SUBCOMMAND", "Google Analytics commands"
    subcommand "analytics", Class.new(Thor) {
      desc "top", "Show top pages from GA4 (last N days)"
      option :days, type: :numeric, default: 7
      option :limit, type: :numeric, default: 20
      def top
        config = IthGrowth::CLI.context.config
        unless config.ga4_property_id && config.ga4_credentials_path
          say "Analytics not configured. Add analytics.ga4_property_id and analytics.credentials_path to config.yml"
          return
        end
        client = IthGrowth::Analytics::GaClient.new(
          property_id: config.ga4_property_id,
          credentials_path: config.ga4_credentials_path
        )
        pages = client.top_pages(days: options[:days], limit: options[:limit])
        say client.format_as_markdown(pages)
      end
    }

    desc "search SUBCOMMAND", "Google Search Console commands"
    subcommand "search", Class.new(Thor) {
      desc "top", "Show top queries from Search Console (last N days)"
      option :days, type: :numeric, default: 28
      option :limit, type: :numeric, default: 20
      option :pages, type: :boolean, default: false, desc: "Show top pages instead of queries"
      def top
        config = IthGrowth::CLI.context.config
        unless config.gsc_site_url && config.gsc_credentials_path
          say "Search Console not configured. Add search_console.site_url and search_console.credentials_path to config.yml"
          return
        end
        client = IthGrowth::Analytics::SearchConsoleClient.new(
          site_url: config.gsc_site_url,
          credentials_path: config.gsc_credentials_path
        )
        if options[:pages]
          rows = client.top_pages(days: options[:days], limit: options[:limit])
          say client.format_as_markdown(rows, dimension_label: "Page")
        else
          rows = client.top_queries(days: options[:days], limit: options[:limit])
          say client.format_as_markdown(rows, dimension_label: "Query")
        end
      end
    }

    desc "report NAME", "Generate report: weekly"
    def report(name)
      abort "Only weekly report is supported" unless name == "weekly"

      self.class.context.workflow(:weekly).run.each { |file| say file }
    end

    def self.context
      config = Config.load
      writer = Outputs::Writer.new(base_dir: config.output_dir)
      logger = Logger.new(output_dir: config.output_dir)
      client = case config.ai_provider
               when "openai" then AI::OpenaiClient.new
               when "anthropic" then AI::AnthropicClient.new
               when "fake" then AI::FakeClient.new
               else raise "Unsupported AI provider: #{config.ai_provider}"
               end
      prompt_runner = AI::PromptRunner.new(client: client)
      Context.new(config: config, writer: writer, logger: logger, prompt_runner: prompt_runner)
    end

    class Context
      attr_reader :config

      def initialize(config:, writer:, logger:, prompt_runner:)
        @config = config
        @writer = writer
        @logger = logger
        @prompt_runner = prompt_runner
      end

      def workflow(name)
        klass = {
          analysis: Workflows::ArticleAnalysisWorkflow,
          distribution: Workflows::DistributionWorkflow,
          seo: Workflows::SeoWorkflow,
          conversion: Workflows::ConversionWorkflow,
          daily: Workflows::DailyWorkflow,
          weekly: Workflows::WeeklyWorkflow
        }.fetch(name) { raise "Unknown workflow: #{name}" }
        klass.new(config: @config, writer: @writer, logger: @logger, prompt_runner: @prompt_runner)
      end
    end
  end
end
