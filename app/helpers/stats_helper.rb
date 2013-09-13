module StatsHelper
  def cloud_tag_font_size(cloud, cloud_tag)
    (9 + 2 * cloud.relative_size(cloud_tag))
  end
end
