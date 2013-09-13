class TagCloud
  LEVELS = 10

  attr_reader :current_user
  attr_reader :tags_min
  attr_reader :tags_for_cloud
  attr_reader :tags_divisor
  attr_reader :tags_min_90days
  attr_reader :tags_divisor_90days
  attr_reader :tags_for_cloud_90days

  def initialize(current_user)
    @current_user    = current_user
  end

  def compute
    # tag cloud code inspired by this article
    #  http://www.juixe.com/techknow/index.php/2006/07/15/acts-as-taggable-tag-cloud/

    # Get the tag cloud for all tags for actions
    @tags_for_cloud = get_tags_for_cloud

    max, @tags_min = 0, 0
    @tags_for_cloud.each { |t|
      max = [t.count.to_i, max].max
      @tags_min = [t.count.to_i, @tags_min].min
    }

    @tags_for_cloud_90days = get_tags_for_cloud({
      cut_off: 3.months.ago.beginning_of_day
    })

    @tags_divisor = ((max - @tags_min) / LEVELS) + 1

    max_90days, @tags_min_90days = 0, 0
    @tags_for_cloud_90days.each { |t|
      max_90days = [t.count.to_i, max_90days].max
      @tags_min_90days = [t.count.to_i, @tags_min_90days].min
    }

    @tags_divisor_90days = ((max_90days - @tags_min_90days) / LEVELS) + 1
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

end
