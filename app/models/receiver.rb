class Receiver < ApplicationRecord
  belongs_to :award
  validates :ein, uniqueness: true, allow_nil: true
end
