require "net/http"
require "json"
require "uri"
require "date"

module IthGrowth
  module Analytics
    class SearchConsoleClient
      SCOPE = "https://www.googleapis.com/auth/webmasters.readonly"
      API_BASE = "https://www.googleapis.com/webmasters/v3/sites"

      def initialize(site_url:, credentials_path:)
        @site_url = site_url
        @credentials_path = credentials_path
      end

      def top_queries(days: 28, limit: 20)
        parse_response(query(dimensions: ["query"], days: days, limit: limit))
      end

      def top_pages(days: 28, limit: 20)
        parse_response(query(dimensions: ["page"], days: days, limit: limit))
      end

      def page_queries(page_url:, days: 28, limit: 10)
        parse_response(query(dimensions: ["query"], days: days, limit: limit, page_url: page_url))
      end

      def format_as_markdown(rows, dimension_label: "Query")
        return "_No data_" if rows.empty?

        header = "| #{dimension_label} | Clicks | Impressions | CTR | Position |"
        separator = "|#{"-" * (dimension_label.length + 2)}|--------|-------------|-----|----------|"
        lines = rows.map do |r|
          "| #{r[:dimension]} | #{r[:clicks]} | #{r[:impressions]} | #{(r[:ctr] * 100).round(1)}% | #{r[:position].round(1)} |"
        end
        ([header, separator] + lines).join("\n")
      end

      def parse_response(data)
        (data["rows"] || []).map do |row|
          {
            dimension: row["keys"].first,
            clicks: row["clicks"].to_i,
            impressions: row["impressions"].to_i,
            ctr: row["ctr"].to_f,
            position: row["position"].to_f
          }
        end
      end

      private

      def query(dimensions:, days:, limit:, page_url: nil)
        end_date = Date.today
        start_date = end_date - days

        body = {
          startDate: start_date.to_s,
          endDate: end_date.to_s,
          dimensions: dimensions,
          rowLimit: limit,
          orderBy: [{ fieldName: "clicks", sortOrder: "DESCENDING" }]
        }
        if page_url
          body[:dimensionFilterGroups] = [{
            filters: [{ dimension: "page", expression: page_url }]
          }]
        end

        encoded_url = URI.encode_www_form_component(@site_url)
        uri = URI("#{API_BASE}/#{encoded_url}/searchAnalytics/query")

        http = Net::HTTP.new(uri.host, uri.port)
        http.use_ssl = true

        req = Net::HTTP::Post.new(uri.request_uri)
        req["Authorization"] = "Bearer #{fetch_token}"
        req["Content-Type"] = "application/json"
        req.body = body.to_json

        res = http.request(req)
        raise "Search Console API error #{res.code}: #{res.body}" unless res.is_a?(Net::HTTPSuccess)
        JSON.parse(res.body)
      end

      def fetch_token
        require "googleauth"
        creds = Google::Auth::ServiceAccountCredentials.make_creds(
          json_key_io: File.open(@credentials_path),
          scope: SCOPE
        )
        creds.fetch_access_token!["access_token"]
      end
    end
  end
end
