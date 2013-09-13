# tag cloud code inspired by this article
#  http://www.juixe.com/techknow/index.php/2006/07/15/acts-as-taggable-tag-cloud/

class TagCloud
  LEVELS = 10

  def initialize(current_user, cut_off = nil)
    @current_user = current_user
    @cut_off      = cut_off
  end

  def tags_for_cloud
    @tags_for_cloud ||= get_tags_for_cloud
  end

  def tags_min
    return @tags_min if @tags_min
    calculate_min_and_max
    @tags_min
  end

  def tags_max
    return @tags_max if @tags_max
    calculate_min_and_max
    @tags_max
  end

  def tags_divisor
    @tags_divisor ||= ((tags_max - tags_min) / LEVELS) + 1
  end

  private

  def get_tags_for_cloud
    query = "SELECT tags.id, name, count(*) AS count"
    query << " FROM taggings, tags, todos"
    query << " WHERE tags.id = tag_id"
    query << " AND taggings.taggable_id = todos.id"
    query << " AND todos.user_id = ?"
    query << " AND taggings.taggable_type='Todo' "

    if @cut_off
      query << "AND (todos.created_at > ? OR todos.completed_at > ?)"
    end

    query << " GROUP BY tags.id, tags.name"
    query << " ORDER BY count DESC, name"
    query << " LIMIT 100"

    sql_params = [query, @current_user.id]
    sql_params += [@cut_off, @cut_off] if @cut_off

    Tag.find_by_sql(sql_params).sort_by { |tag| tag.name.downcase }
  end

  def calculate_min_and_max
    @tags_min, @tags_max = 0, 0
    tags_for_cloud.each { |t|
      @tags_max = [t.count.to_i, @tags_max].max
      @tags_min = [t.count.to_i, @tags_min].min
    }
  end

end
