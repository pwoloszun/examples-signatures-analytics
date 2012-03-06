module AssetsHelpers

  ASSETS_DIR = Rails.root.join("spec/data")

  def open_asset filename
    ASSETS_DIR.join(filename).open
  end

  def uploaded_file filename, type
    Rack::Test::UploadedFile.new(ASSETS_DIR.join(filename), type)
  end

end
