class TagsController < ApplicationController
  def index
    if current_user == nil
      redirect_to("/users/sign_in")
      return
    end

    matching_tags = Tag.where({ :user_id => current_user.id })
    @list_of_tags = matching_tags.order({ :name => :asc })

    render({ :template => "tag_templates/index" })
  end

  def show
  if current_user == nil
    redirect_to("/users/sign_in")
    return
  end

  @the_tag = Tag.where({ :id => params.fetch("id"), :user_id => current_user.id }).at(0)

  if @the_tag == nil
    redirect_to("/categories")
    return
  end

  matching_item_tags = ItemTag.where({ :tag_id => @the_tag.id })
  @list_of_items = []

  matching_item_tags.each do |an_item_tag|
    the_item = Item.where({ :id => an_item_tag.item_id, :user_id => current_user.id }).at(0)
    if the_item != nil
      @list_of_items.push(the_item)
    end
  end

  sort_by = params.fetch("sort_by", "")

  if sort_by == "price"
    @list_of_items = @list_of_items.sort_by { |item| item.price.to_f }.reverse
  elsif sort_by == "priority"
    priority_order = { "High" => 1, "Medium" => 2, "Low" => 3, "None" => 4, nil => 5, "" => 5 }
    @list_of_items = @list_of_items.sort_by { |item| priority_order.fetch(item.priority, 5) }
  elsif sort_by == "buy_by"
    @list_of_items = @list_of_items.sort_by { |item| item.buy_by || Date.new(9999, 12, 31) }
  end

  render({ :template => "tag_templates/show" })
  end

  def destroy
  if current_user == nil
    redirect_to("/users/sign_in")
    return
  end

  the_id = params.fetch("path_id")
  the_tag = Tag.where({ :id => the_id, :user_id => current_user.id }).at(0)

  if the_tag != nil
    matching_item_tags = ItemTag.where({ :tag_id => the_tag.id })
    matching_item_tags.each do |an_item_tag|
      an_item_tag.destroy
    end

    the_tag.destroy
  end
  redirect_to("/categories", { :notice => "Category deleted successfully." })
  end

  def create
  if current_user == nil
    redirect_to("/users/sign_in")
    return
  end

  category_name = params.fetch("query_category_name").strip

  if category_name == ""
    redirect_to("/categories", { :alert => "Category name can't be blank." })
    return
  end

  existing = Tag.where({ :user_id => current_user.id, :name => category_name }).at(0)

  if existing != nil
    redirect_to("/categories", { :alert => "Category '#{category_name}' already exists." })
    return
  end

  the_tag = Tag.new
  the_tag.user_id = current_user.id
  the_tag.name = category_name
  the_tag.save

  redirect_to("/categories", { :notice => "Category '#{category_name}' created!" })
  end

end
