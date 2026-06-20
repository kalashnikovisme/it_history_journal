require "net/http"
require "json"
require "uri"

module IthGrowth
  module Analytics
    class GaClient
      SCOPE = "https://www.googleapis.com/auth/analytics.readonly"
      API_BASE = "https://analyticsdata.googleapis.com"

      def initialize(property_id:, credentials_path:)
        @property_id = property_id
        @credentials_path = credentials_path
      end

      def top_pages(days: 7, limit: 20)
        body = {
          dateRanges: [{ startDate: "#{days}daysAgo", endDate: "today" }],
          dimensions: [{ name: "pagePath" }, { name: "pageTitle" }],
          metrics: [
            { name: "screenPageViews" },
            { name: "bounceRate" },
            { name: "averageSessionDuration" }
          ],
          orderBys: [{ metric: { metricName: "screenPageViews" }, desc: true }],
          limit: limit
        }
        parse_response(run_report(body))
      end

      def page_stats(page_path:, days: 28)
        body = {
          dateRanges: [{ startDate: "#{days}daysAgo", endDate: "today" }],
          dimensions: [{ name: "pagePath" }],
          metrics: [
            { name: "screenPageViews" },
            { name: "bounceRate" },
            { name: "averageSessionDuration" }
          ],
          dimensionFilter: {
            filter: {
              fieldName: "pagePath",
              stringFilter: { matchType: "EXACT", value: page_path }
            }
          },
          limit: 1
        }
        parse_response(run_report(body)).first
      end

      def format_as_markdown(pages)
        return "_No data_" if pages.empty?

        rows = pages.map do |p|
          "| #{p[:path]} | #{p[:title]} | #{p[:views]} | #{(p[:bounce_rate] * 100).round(1)}% | #{p[:avg_duration].round}s |"
        end
        [
          "| Path | Title | Views | Bounce Rate | Avg Duration |",
          "|------|-------|-------|-------------|--------------|",
          *rows
        ].join("\n")
      end

      def parse_response(data)
        (data["rows"] || []).map do |row|
          dims = row["dimensionValues"].map { |v| v["value"] }
          metrics = row["metricValues"].map { |v| v["value"] }
          {
            path: dims[0],
            title: dims[1],
            views: metrics[0].to_i,
            bounce_rate: metrics[1].to_f,
            avg_duration: metrics[2].to_f
          }
        end
      end

      private

      def run_report(body)
        require "googleauth"
        uri = URI("#{API_BASE}/v1beta/properties/#{@property_id}:runReport")

        http = Net::HTTP.new(uri.host, uri.port)
        http.use_ssl = true

        req = Net::HTTP::Post.new(uri.path)
        req["Authorization"] = "Bearer #{fetch_token}"
        req["Content-Type"] = "application/json"
        req.body = body.to_json

        res = http.request(req)
        raise "GA4 API error #{res.code}: #{res.body}" unless res.is_a?(Net::HTTPSuccess)
        JSON.parse(res.body)
      end

      def fetch_token
        creds = Google::Auth::ServiceAccountCredentials.make_creds(
          json_key_io: File.open(@credentials_path),
          scope: SCOPE
        )
        creds.fetch_access_token!["access_token"]
      end
    end
  end
end
