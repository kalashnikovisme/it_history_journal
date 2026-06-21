require "google/apis/drive_v3"
require "googleauth"
require "json"

module Video
  class DriveUploader
    SCOPE = "https://www.googleapis.com/auth/drive"
    DEFAULT_CREDENTIALS = "growth/config/ga4_credentials.json"

    def self.configured?
      false
    end

    def initialize
      @root_id = ENV["GOOGLE_DRIVE_ROOT_FOLDER_ID"].to_s
      raise "GOOGLE_DRIVE_ROOT_FOLDER_ID is not set." if @root_id.empty?
      raise "Credentials not found: #{DEFAULT_CREDENTIALS}" unless File.exist?(DEFAULT_CREDENTIALS)

      @service = build_service
    end

    # Upload narration.mp3 and final.mp4 for the given article.
    # Returns hash { mp3: web_link, mp4: web_link }.
    def upload(article_info, paths)
      folder_id = ensure_folder_path(article_info)

      results = {}
      results[:mp3] = upload_file(paths.narration_mp3, folder_id, "audio/mpeg") if File.exist?(paths.narration_mp3)
      results[:mp4] = upload_file(paths.final_mp4,     folder_id, "video/mp4")  if File.exist?(paths.final_mp4)
      results
    end

    private

    def build_service
      credentials = Google::Auth::ServiceAccountCredentials.make_creds(
        json_key_io: File.open(DEFAULT_CREDENTIALS),
        scope: SCOPE
      )
      service = Google::Apis::DriveV3::DriveService.new
      service.authorization = credentials
      service
    end

    # Ensures Digest/{mon}/{dd}/{slug} exists under the root folder.
    def ensure_folder_path(info)
      parts = ["Digest", info[:month_abbr], info[:day].to_s, info[:slug_dir]]
      parent_id = @root_id
      parts.each { |name| parent_id = find_or_create_folder(name, parent_id) }
      parent_id
    end

    def find_or_create_folder(name, parent_id)
      escaped = name.gsub("'", "\\'")
      q = "name = '#{escaped}' and mimeType = 'application/vnd.google-apps.folder' " \
          "and '#{parent_id}' in parents and trashed = false"
      result = @service.list_files(
        q: q, fields: "files(id)", spaces: "drive",
        include_items_from_all_drives: true, supports_all_drives: true
      )
      return result.files.first.id if result.files.any?

      meta = Google::Apis::DriveV3::File.new(
        name: name,
        mime_type: "application/vnd.google-apps.folder",
        parents: [parent_id]
      )
      @service.create_file(meta, fields: "id", supports_all_drives: true).id
    end

    def upload_file(local_path, folder_id, mime_type)
      filename = File.basename(local_path)
      escaped  = filename.gsub("'", "\\'")
      q = "name = '#{escaped}' and '#{folder_id}' in parents and trashed = false"
      existing = @service.list_files(
        q: q, fields: "files(id)", spaces: "drive",
        include_items_from_all_drives: true, supports_all_drives: true
      )

      if existing.files.any?
        @service.update_file(
          existing.files.first.id,
          upload_source: local_path,
          content_type: mime_type,
          fields: "id,web_view_link",
          supports_all_drives: true
        ).web_view_link
      else
        meta = Google::Apis::DriveV3::File.new(name: filename, parents: [folder_id])
        @service.create_file(
          meta,
          upload_source: local_path,
          content_type: mime_type,
          fields: "id,web_view_link",
          supports_all_drives: true
        ).web_view_link
      end
    end
  end
end
