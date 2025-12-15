class ItemsController < ApplicationController
  def index
    if current_user == nil
      redirect_to("/users/sign_in")
      return
    end

    matching_items = Item.where({ :user_id => current_user.id })
    @list_of_items = matching_items.order({ :created_at => :desc })

    render({ :template => "item_templates/index" })
  end

  def show
  if current_user == nil
    redirect_to("/users/sign_in")
    return
  end

  the_id = params.fetch("path_id")
  @the_item = Item.where({ :id => the_id, :user_id => current_user.id }).at(0)

  if @the_item == nil
    redirect_to("/categories")
    return
  end

  item_tag = ItemTag.where({ :item_id => @the_item.id }).at(0)
  if item_tag != nil
    @the_tag = Tag.where({ :id => item_tag.tag_id }).at(0)
  end

  render({ :template => "item_templates/show" })
  end

  def create
  if current_user == nil
    redirect_to("/users/sign_in")
    return
  end

  the_url = params.fetch("query_url", "")
  if the_url == ""
    redirect_to("/", { :alert => "URL is required." })
    return
  end

  the_item = Item.new
  the_item.user_id = current_user.id
  the_item.url = params.fetch("query_url")
  the_item.buy_by = params.fetch("query_buy_by", "")
  the_item.notes = params.fetch("query_notes", "")
  the_item.priority = params.fetch("query_priority", "None")

  item_details = get_item_details_from_ai(the_item.url)
  the_item.title = item_details[:title]
  the_item.image_url = item_details[:image_url]
  manual_price = params.fetch("query_price", "")
  if manual_price != ""
    the_item.price = manual_price
  else
    the_item.price = item_details[:price]
  end
  the_item.currency = item_details[:currency]
  the_item.description = item_details[:description]
  the_item.brand = item_details[:store]

  if the_item.valid?
    the_item.save

    selected_tag = params.fetch("query_tag_name", "")

    if selected_tag != ""
      category_name = selected_tag
    else
      category_name = item_details[:category]
    end

    matching_tags = Tag.where({ :user_id => current_user.id, :name => category_name })
    the_tag = matching_tags.at(0)

    if the_tag == nil
      the_tag = Tag.new
      the_tag.user_id = current_user.id
      the_tag.name = category_name
      the_tag.save
    end

    link = ItemTag.new
    link.item_id = the_item.id
    link.tag_id = the_tag.id
    link.save

    redirect_to("/", { :notice => "Item added to #{category_name}!" })
  else
    redirect_to("/", { :alert => the_item.errors.full_messages.to_sentence })
    end
  end
  
  def destroy
  if current_user == nil
    redirect_to("/users/sign_in")
    return
  end

  the_id = params.fetch("path_id")
  the_item = Item.where({ :id => the_id, :user_id => current_user.id }).at(0)

  from_all_items = params.fetch("from", "") == "all"

  category_id = nil
  if the_item != nil
    item_tag = ItemTag.where({ :item_id => the_item.id }).at(0)
    if item_tag != nil
      category_id = item_tag.tag_id
    end

    matching_item_tags = ItemTag.where({ :item_id => the_item.id })
    matching_item_tags.each do |an_item_tag|
      an_item_tag.destroy
    end

    the_item.destroy
  end

  if from_all_items
    redirect_to("/all_items", { :notice => "Item deleted successfully." })
  elsif category_id != nil
    redirect_to("/categories/" + category_id.to_s, { :notice => "Item deleted successfully." })
  else
    redirect_to("/categories", { :notice => "Item deleted successfully." })
  end
  end


  def get_item_details_from_ai(url)
  require "http"
  require "json"

  microlink_url = "https://api.microlink.io?url=" + url
  
  raw_microlink = HTTP.get(microlink_url).to_s
  parsed_microlink = JSON.parse(raw_microlink)
  
  microlink_data = parsed_microlink.fetch("data", {})
  
  scraped_title = microlink_data.fetch("title", "")
  if scraped_title == nil
    scraped_title = ""
  end
  scraped_image = ""
  if microlink_data["image"] != nil
    scraped_image = microlink_data["image"].fetch("url", "")
    if scraped_image == nil
      scraped_image = ""
    end
  end

  matching_tags = Tag.where({ :user_id => current_user.id })
  existing_tags = []
  matching_tags.each do |a_tag|
    existing_tags.push(a_tag.name)
  end
  
  if existing_tags.count > 0
    category_list = ""
    existing_tags.each do |tag_name|
      if category_list == ""
        category_list = tag_name
      else
        category_list = category_list + ", " + tag_name
      end
    end
    category_instruction = "Pick the best category from this list: #{category_list}. If none fit, create a new short category name."
  else
    category_instruction = "Suggest a short category name (1-2 words) like: Clothes, Electronics, Books, Home, Beauty, Sports, Toys, Food, Gifts."
  end

  prompt = "Based on this product URL: #{url}
And product title: #{scraped_title}

Extract the following information and respond in this exact format:
TITLE: [clean product name without extra text]
PRICE: [number only, no symbols - find the actual current price for this exact product]
CURRENCY: [USD, EUR, etc.]
STORE: [store name like Amazon, Nike, Revolve, Nordstrom, etc.]
CATEGORY: [#{category_instruction}]
DESCRIPTION: [a short 1-2 sentence visual description including color, material, and style]

If you cannot determine something, leave it blank. Respond with ONLY the format above, nothing else."

  api_key = ENV["OPENAI_API_KEY"]

  request_headers_hash = {
    "Authorization" => "Bearer " + api_key,
    "content-type" => "application/json"
  }

  request_body_hash = {
    "model" => "gpt-4.1-nano",
    "messages" => [
      {
        "role" => "user",
        "content" => prompt
      }
    ]
  }

  request_body_json = JSON.generate(request_body_hash)

  raw_response = HTTP.headers(request_headers_hash).post(
    "https://api.openai.com/v1/chat/completions",
    :body => request_body_json
  ).to_s

  parsed_response = JSON.parse(raw_response)

  result = parsed_response.fetch("choices").at(0).fetch("message").fetch("content")

  title = ""
  price = ""
  currency = "USD"
  store = ""
  category = "Other"
  description = ""

  result.each_line do |line|
    if line.include?("TITLE:")
      title = line.sub("TITLE:", "").strip
    elsif line.include?("PRICE:")
      price = line.sub("PRICE:", "").strip
    elsif line.include?("CURRENCY:")
      currency = line.sub("CURRENCY:", "").strip
    elsif line.include?("STORE:")
      store = line.sub("STORE:", "").strip
    elsif line.include?("CATEGORY:")
      category = line.sub("CATEGORY:", "").strip
    elsif line.include?("DESCRIPTION:")
      description = line.sub("DESCRIPTION:", "").strip
    end
  end

  if title == ""
    title = scraped_title
  end

  image_url = scraped_image

  return { title: title, price: price, currency: currency, category: category, store: store, description: description, image_url: image_url }
  end

  def all
  if current_user == nil
    redirect_to("/users/sign_in")
    return
  end

  sort_by = params.fetch("sort_by", "")

  if sort_by == "price"
    all_items = Item.where({ :user_id => current_user.id })
    
    # Sort by price manually (high to low)
    sorted_items = []
    remaining_items = []
    
    all_items.each do |an_item|
      remaining_items.push(an_item)
    end
    
    while remaining_items.count > 0
      highest_item = remaining_items.at(0)
      remaining_items.each do |an_item|
        if an_item.price.to_f > highest_item.price.to_f
          highest_item = an_item
        end
      end
      sorted_items.push(highest_item)
      remaining_items = remaining_items - [highest_item]
    end
    
    @list_of_items = sorted_items
  elsif sort_by == "priority"
    all_items = Item.where({ :user_id => current_user.id })
    
    high_items = []
    medium_items = []
    low_items = []
    none_items = []
    
    all_items.each do |an_item|
      if an_item.priority == "High"
        high_items.push(an_item)
      elsif an_item.priority == "Medium"
        medium_items.push(an_item)
      elsif an_item.priority == "Low"
        low_items.push(an_item)
      else
        none_items.push(an_item)
      end
    end
    
    @list_of_items = high_items + medium_items + low_items + none_items
  elsif sort_by == "buy_by"
    @list_of_items = Item.where({ :user_id => current_user.id }).order({ :buy_by => :asc })
  else
    @list_of_items = Item.where({ :user_id => current_user.id }).order({ :created_at => :desc })
  end

  render({ :template => "item_templates/all" })
  end
end
