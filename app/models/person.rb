class Person < ApplicationRecord
  include Lockable
  has_many :items
  validates :first_name, :last_name, presence: true

  def fingerprint_excluded_fields
    [:items_count]
  end
end
