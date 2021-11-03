class Filer < ApplicationRecord
    has_many :awards
    validates :ein, uniqueness: true
end
