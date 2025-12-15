class PagesController < ApplicationController
  def homepage
    if current_user == nil
      @list_of_items = []
      @list_of_tags = []
    else
      matching_items = Item.where({ :user_id => current_user.id })
      @list_of_items = matching_items.order({ :created_at => :desc })

      matching_tags = Tag.where({ :user_id => current_user.id })
      @list_of_tags = matching_tags.order({ :name => :asc })
    end

    render({ :template => "page_templates/homepage" })
  end
end
