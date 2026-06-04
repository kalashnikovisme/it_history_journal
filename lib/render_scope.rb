require 'haml'

class RenderScope
  TEMPLATES_DIR = File.expand_path('../../templates', __FILE__)

  def partial(name, locals = {})
    path = File.join(TEMPLATES_DIR, "_#{name}.html.haml")
    raise "Partial not found: #{path}" unless File.exist?(path)
    src = File.read(path)
    Haml::Template.new { src }.render(self, locals)
  end
end
