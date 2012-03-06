module LoggedInUserContext

  def self.included base
    base.let(:account) { Factory.create(:account) }
    base.let(:current_user) { Factory.create(:user, :name => "John Smith", :account => account) }
    base.before(:each) do
      log_in(current_user)
    end
  end

end
