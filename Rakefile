require_relative 'lib/builder'

task default: :build

desc 'Build the static site into _site/'
task :build do
  Builder.new.build
  puts "Built to _site/"
end

desc 'Serve the site locally on port 4000'
task :serve do
  require 'rack'
  require 'webrick'
  Rake::Task[:build].invoke
  app = Rack::Builder.new do
    use Rack::Static, urls: [''], root: '_site', index: 'index.html'
    run ->(env) { [404, { 'Content-Type' => 'text/plain' }, ['Not Found']] }
  end
  Rack::Handler::WEBrick.run app, Port: 4000, Host: '0.0.0.0'
end

desc 'Remove the _site/ directory'
task :clean do
  require 'fileutils'
  FileUtils.rm_rf('_site')
  puts 'Cleaned _site/'
end
