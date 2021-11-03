class Receiver < ApplicationRecord
  belongs_to :award
  validates :ein, uniqueness: true
end
