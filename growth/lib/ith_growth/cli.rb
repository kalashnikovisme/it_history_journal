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

module IthGrowth
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
    subcommand "article", Class.new(Thor) {
      desc "analyze PATH", "Analyze an article"
      def analyze(path)
        IthGrowth::CLI.context.workflow(:analysis).run(path).each { |file| say file }
      end

      desc "promote PATH", "Generate analysis, distribution, SEO, and conversion drafts"
      def promote(path)
        ctx = IthGrowth::CLI.context
        files = ctx.workflow(:analysis).run(path) +
          ctx.workflow(:distribution).run(path) +
          ctx.workflow(:seo).run(path) +
          ctx.workflow(:conversion).run(path)
        files.each { |file| say file }
      end
    }

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
