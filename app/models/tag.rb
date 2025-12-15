# == Schema Information
#
# Table name: tags
#
#  id         :bigint           not null, primary key
#  name       :string
#  tag_type   :string
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  user_id    :bigint           not null
#
# Indexes
#
#  index_tags_on_user_id  (user_id)
#
# Foreign Keys
#
#  fk_rails_...  (user_id => users.id)
#
class Tag < ApplicationRecord
  validates :name, presence: true

  belongs_to :user, class_name: "User", foreign_key: "user_id"
  has_many :item_tags, class_name: "ItemTag", foreign_key: "tag_id", dependent: :destroy
end
