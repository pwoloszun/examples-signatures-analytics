module Mongoid::TimestampsHelpers

  def self.included base
    base.it { should have_field(:created_at).of_type(Time) }
    base.it { should have_field(:updated_at).of_type(Time) }
  end

end