class Item < ApplicationRecord
  belongs_to :person, optional: true
  validates :name, presence: true
end
