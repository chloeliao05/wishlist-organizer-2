Rails.application.routes.draw do
  devise_for :users
  root to: "pages#homepage"

  post("/insert_item", { :controller => "items", :action => "create" })
  get("/items",        { :controller => "items", :action => "index" })
  get("/categories", { :controller => "tags", :action => "index" })
  get("/categories/:id", { :controller => "tags", :action => "show" })
  get("/delete_category/:path_id", { :controller => "tags", :action => "destroy" })
  post("/insert_category", { :controller => "tags", :action => "create" })
  get("/items/:path_id", { :controller => "items", :action => "show" })
  get("/delete_item/:path_id", { :controller => "items", :action => "destroy" })
  get("/all_items", { :controller => "items", :action => "all" })

end
