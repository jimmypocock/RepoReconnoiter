class WhitelistedUser < ApplicationRecord
  #--------------------------------------
  # ASSOCIATIONS
  #--------------------------------------

  has_many :users, dependent: :restrict_with_error

  #--------------------------------------
  # VALIDATIONS
  #--------------------------------------

  validates :github_id, presence: true, uniqueness: true, numericality: { only_integer: true, greater_than: 0 }
  validates :github_username, presence: true
end
