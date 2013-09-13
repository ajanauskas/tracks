# tag cloud code inspired by this article
#  http://www.juixe.com/techknow/index.php/2006/07/15/acts-as-taggable-tag-cloud/

class TagCloud
  LEVELS = 10

  def initialize(current_user, cut_off = nil)
    @current_user = current_user
    @cut_off      = cut_off
  end

  def tags
    @tags ||= get_tags
  end

  def min
    return @min if @min
    calculate_min_and_max
    @min
  end

  def max
    return @max if @max
    calculate_min_and_max
    @max
  end

  def divisor
    @divisor ||= ((max - min) / LEVELS) + 1
  end

  private

  def get_tags
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
    @min, @max = 0, 0
    tags.each { |t|
      @max = [t.count.to_i, @max].max
      @min = [t.count.to_i, @min].min
    }
  end

end
