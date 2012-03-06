class Analytics::SignatureStatistic
  include Mongoid::Document
  include Mongoid::Timestamps

  belongs_to :signature
  has_many :link_statistics, class_name: 'Analytics::LinkStatistic'

  validates_presence_of :signature

  field :impressions_count, type: Integer, default: 0

  def self.find_by_signature_and_month signature, datetime
    stat = self.first(conditions: {signature_id: signature.id, :created_at.gte => datetime.beginning_of_month, :created_at.lte => datetime.end_of_month})
    stat || self.create(signature_id: signature.id, created_at: datetime.beginning_of_month)
  end

  def self.find_all_time_by_signature signature
    all_stats = self.all_of(signature_id: signature.id).to_a
    self.new(signature_id: signature.id, impressions_count: all_stats.sum(&:impressions_count))
  end

  def add_impression
    self.impressions_count += 1
  end

end
