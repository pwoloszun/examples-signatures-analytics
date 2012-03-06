class Analytics::LinkStatistic
  include Mongoid::Document
  include Mongoid::Timestamps

  belongs_to :link

  field :clicks_count, type: Integer, default: 0

  validates_presence_of :link

  def self.find_by_link_and_month link, datetime
    stat = self.first(conditions: {link_id: link.id, :created_at.gte => datetime.beginning_of_month, :created_at.lte => datetime.end_of_month})
    stat || self.create(link_id: link.id, created_at: datetime.beginning_of_month)
  end

  def self.find_all_time_by_link link
    all_links_stats = self.all_of(link_id: link.id).to_a
    self.new(link_id: link.id, clicks_count: all_links_stats.sum(&:clicks_count))
  end

  def add_click
    self.clicks_count += 1
  end

end
