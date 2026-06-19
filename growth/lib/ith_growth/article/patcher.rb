require "date"

module IthGrowth
  module Article
    class Patcher
      def apply(path, patch)
        raw = File.read(path)
        return path unless raw.start_with?("---\n")

        _, front, body = raw.split(/^---\s*\n/, 3)
        front ||= ""
        body  ||= ""

        patch.each do |key, value|
          line = "#{key}: #{yaml_scalar(value)}"
          if front.match?(/^#{Regexp.escape(key)}:/)
            front = front.gsub(/^#{Regexp.escape(key)}:[ \t]*.*$/, line)
          else
            front += "#{line}\n"
          end
        end

        today = "updated_at: #{yaml_scalar(Date.today.to_s)}"
        if front.match?(/^updated_at:/)
          front = front.gsub(/^updated_at:[ \t]*.*$/, today)
        else
          front += "#{today}\n"
        end

        File.write(path, "---\n#{front}---\n#{body}")
        path
      end

      private

      def yaml_scalar(value)
        "\"#{value.to_s.gsub("\\", "\\\\").gsub('"', '\\"')}\""
      end
    end
  end
end
