require "digest"
require "json"
require "ith_growth/ai/client"

module IthGrowth
  module AI
    class FakeClient < Client
      def complete(prompt:, system: nil, model: nil, temperature: 0.4)
        digest = Digest::SHA256.hexdigest(prompt)[0, 12]
        <<~TEXT
          # Fake AI Output

          Provider: fake
          Model: #{model || "fake-local"}
          Digest: #{digest}

          This deterministic draft was generated locally for development and tests.

          ## Key Suggestions

          - Clarify the historical stakes in the opening paragraph.
          - Add internal links to related IT History Journal articles.
          - Test one version with a soft Patreon/Boosty CTA and one without CTA.
        TEXT
      end

      def provider
        "fake"
      end
    end
  end
end
