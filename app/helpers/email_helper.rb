module EmailHelper
  def lookup_asset(filename)
    Webpacker.manifest.lookup filename
  end

  def get_full_path_to_asset(filename)
    Webpacker.
      manifest.
      config.
      public_path.
      join(lookup_asset(filename).sub(/^\//, ""))
  end


  def email_image_tag(name, **options)
    image = name.starts_with?("media/images/") ? name : "media/images/#{name}"

    if Rails.env.development?
      attachments[image] = {
        mime_type: "image/#{image.split(".")[-1]}",
        content: File.read(get_full_path_to_asset(image))
      }
      image = attachments[image].url
      return image_tag image, **options
    else
      image_pack_tag image, **options
    end
  end
end
