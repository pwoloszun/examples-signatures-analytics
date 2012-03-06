RSpec.configure do |config|
  config.include Devise::TestHelpers, :type => :controller

  def log_in user
    request.env['warden'] = mock(Warden, :authenticate => user, :authenticate! => user)
  end
end
