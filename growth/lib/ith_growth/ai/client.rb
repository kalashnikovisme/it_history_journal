module IthGrowth
  module AI
    class Client
      def complete(prompt:, system: nil, model: nil, temperature: 0.4)
        raise NotImplementedError, "#{self.class} must implement #complete"
      end

      def provider
        self.class.name.split("::").last.sub("Client", "").downcase
      end
    end
  end
end
