module Mongoid::UuidHelpers

  def self.included base
    base.it { should have_field(:uuid).of_type(String) }
    base.it { should validate_presence_of(:uuid) }
  end

end
