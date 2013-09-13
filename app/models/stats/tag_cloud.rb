# tag cloud code inspired by this article
#  http://www.juixe.com/techknow/index.php/2006/07/15/acts-as-taggable-tag-cloud/

class TagCloud
  LEVELS = 10

  attr_reader :current_user
  attr_reader :tags_min
  attr_reader :tags_divisor
  attr_reader :tags_min_90days
  attr_reader :tags_divisor_90days

  def initialize(current_user)
    @current_user = current_user
  end

  def compute
    @tags_min, max               = calculate_min_and_max(tags_for_cloud)
    @tags_divisor                = ((max - @tags_min) / LEVELS) + 1
    @tags_min_90days, max_90days = calculate_min_and_max(tags_for_cloud_90days)
    @tags_divisor_90days         = ((max_90days - @tags_min_90days) / LEVELS) + 1
  end

  def tags_for_cloud
    @tags_for_cloud ||= get_tags_for_cloud
  end


  def tags_for_cloud_90days
    @tags_for_cloud_90days ||= get_tags_for_cloud({
      cut_off: 3.months.ago.beginning_of_day
    })
  end

  private

  def get_tags_for_cloud(options = {})
    cut_off = options[:cut_off]

    query = "SELECT tags.id, name, count(*) AS count"
    query << " FROM taggings, tags, todos"
    query << " WHERE tags.id = tag_id"
    query << " AND taggings.taggable_id = todos.id"
    query << " AND todos.user_id = ?"
    query << " AND taggings.taggable_type='Todo' "

    if cut_off
      query << "AND (todos.created_at > ? OR todos.completed_at > ?)"
    end

    query << " GROUP BY tags.id, tags.name"
    query << " ORDER BY count DESC, name"
    query << " LIMIT 100"

    sql_params = [query, current_user.id]
    sql_params += [cut_off, cut_off] if cut_off

    Tag.find_by_sql(sql_params).sort_by { |tag| tag.name.downcase }
  end

  def calculate_min_and_max(tags)
    min, max = 0, 0
    tags_for_cloud.each { |t|
      max = [t.count.to_i, max].max
      min = [t.count.to_i, min].min
    }
    return [min, max]
  end

end
