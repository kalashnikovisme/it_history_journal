require "fileutils"
require "json"

module IthGrowth
  module Outputs
    class Writer
      attr_reader :base_dir

      def initialize(base_dir:)
        @base_dir = base_dir
      end

      def write(relative_path, content)
        path = File.join(base_dir, relative_path)
        FileUtils.mkdir_p(File.dirname(path))
        File.write(path, content)
        path
      end

      def write_json(relative_path, object)
        write(relative_path, JSON.pretty_generate(object))
      end
    end
  end
end
