# == Schema Information
#
# Table name: items
#
#  id          :bigint           not null, primary key
#  brand       :string
#  buy_by      :date
#  currency    :string
#  description :text
#  image_url   :string
#  notes       :text
#  price       :decimal(, )
#  priority    :string
#  status      :string
#  title       :string
#  url         :string
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#  user_id     :bigint           not null
#
# Indexes
#
#  index_items_on_user_id  (user_id)
#
# Foreign Keys
#
#  fk_rails_...  (user_id => users.id)
#
class Item < ApplicationRecord
  validates :url, presence: true

  belongs_to :user, class_name: "User", foreign_key: "user_id"
  has_many :item_tags, class_name: "ItemTag", foreign_key: "item_id", dependent: :destroy
end
