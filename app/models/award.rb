class Award < ApplicationRecord
  belongs_to :filer
  has_one :receiver
end
