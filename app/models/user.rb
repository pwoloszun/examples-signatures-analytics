class User

  include Mongoid::Document
  extend Forwardable

  field :name, :type => String

  validates :name, :presence => true
  validates_uniqueness_of :email, :case_sensitive => false, :message => "is already taken"

  belongs_to :owned_account, :class_name => "Account", :inverse_of => :owner
  belongs_to :account

  # Include default devise modules. Others available are:
  # :registerable, :token_authenticatable, :encryptable, :confirmable, :lockable, :timeoutable and :omniauthable
  devise :invitable, :database_authenticatable, :recoverable, :rememberable, :trackable, :validatable

  attr_accessible :name, :email, :password, :password_confirmation, :remember_me, :account_id

  def_delegators :account, :plan, :has_reached_signatures_limit?, :has_reached_invited_users_limit?, :has_access_to?

  def account_owner?
    !owned_account.nil?
  end

  def owner_of? account
    account_owner? && owned_account == account
  end

end
