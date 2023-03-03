require 'sinatra'
require 'sinatra/reloader'
require 'slim'
require_relative './model.rb'
enable :sessions

# ----- Account -----

get("/show_register") do
    slim(:register)
end

post("/register") do
    username = params[:username]
    password = params[:password]
    password_confirm = params[:password_confirm]

    # Validering om username är unikt
    used_usernames = db_get_one("User", "name")
    used_usernames.each do |used_username|
        if used_username["name"] == username
            redirect("/invalid")
        end
    end
    
    # Kolla password
    if password == password_confirm
        password_digested = digest_password(password)
        db_insert_into("User", "name, pw_digest", username, password_digested)
        redirect("/show_login")
    else
        redirect("/invalid")
    end
end

get("/show_login") do
    slim(:login)
end

post("/login") do
    
end

post('/logout') do
    session[:id] = nil
    redirect('/games')
end

# ----- Games -----

get("/") do
    redirect("/games")
end

get("/games") do # visa alla spel
    @games = db_get_all_order_asc("Game", "name")
    slim(:"games/index")
end 

post("/games") do # lägg nytt spel
    name = params[:name]

    # kolla om namnet är tomt
    if (is_empty(name))
        redirect("/invalid")
    end

    db_insert_one_into("Game", "name", name)
    redirect("/")
end

get("/games/:id") do # visa ett spel
    game_id = params[:id]
    
    if !is_integer_empty(game_id)
        redirect("/invalid")
    end
    
    @game = db_get_all_equal("Game", "id", game_id).first
    @categories = db_get_all_equal_order_asc("Category", "game_id", game_id, "name") 

    slim(:"games/show")
end

post("/games/:id/update") do
    game_id = params[:id]
    new_name = params[:new_name]

    if !is_integer_empty(game_id)
        redirect("/invalid")
    end

    db_update_condition("Game", "name", new_name, "id", game_id)
    redirect("/games/#{game_id}")
end

post("/games/:id/delete") do
    game_id = params[:id]

    if !is_integer_empty(game_id)
        redirect("/invalid")
    end

    # ta bort alla artiklar, kategorier och relations
    all_categories = db_get_all_equal("Category", "game_id", game_id)
    all_categories.each do |category|
        delete_all_articles_in_category(category["id"])

        db_delete("Article_Category_Relation", "category_id", category["id"])
        db_delete("Category", "id", category["id"])
    end

    db_delete("Game", "id", game_id)
    redirect("/games")
end

# ----- Categories -----

post("/categories") do # lägg till ny kategori
    name = params[:name]
    game_id = params[:game_id]

    # kolla om namnet är tomt
    if (is_empty(name))
        redirect("/invalid")
    end

    db_insert_into("Category", "name, game_id", name, game_id)
    redirect("/games/#{game_id}")
end

get("/categories/:id") do
    cat_id = params[:id]
    if !is_integer_empty(cat_id)
        redirect("/invalid")
    end

    @articles = db_get_articles_in_category(cat_id)
    @category = db_get_all_equal("Category", "id", cat_id).first
    
    game_id = @category["game_id"]
    @game = db_get_all_equal("Game", "id", game_id).first
    
    slim(:"categories/show")
end

post("/categories/:id/update") do
    category_id = params[:id]
    new_name = params[:new_name]

    if !is_integer_empty(category_id)
        redirect("/invalid")
    end

    db_update_condition("Category", "name", new_name, "id", category_id)
    redirect("/categories/#{category_id}")
end

post("/categories/:id/delete") do
    category_id = params[:id]
    game_id = params[:game_id]

    if !is_integer_empty(category_id)
        redirect("/invalid")
    end

    delete_all_articles_in_category(category_id)

    db_delete("Article_Category_Relation", "category_id", category_id)
    db_delete("Category", "id", category_id)
    redirect("/games/#{game_id}")
end

# ----- Articles -----

get("/articles/new") do
    game_id = params[:game_id]
    category_id = params[:category_id]
    @game = db_get_all_equal("Game", "id", game_id).first
    @category = db_get_all_equal("Category", "id", category_id).first
    @all_categories = db_get_all_equal_order_asc("Category", "game_id", game_id, "name")

    slim(:"articles/new")
end

post("/articles") do # lägg till ny artikel
    game_id = params[:game_id]
    primary_category_id = params[:primary_category_id]
    title = params[:new_title]
    text = params[:new_text]

    if (is_empty(title))
        redirect("/invalid")
    end

    # lägg till artikeln
    db_insert_into("Article", "name, text, game_id", title, text, game_id)
    new_article = db_get_all_order_asc("Article", "id").last() # Den nyaste artikeln är alltid sist.

    # lägg till i article_category_relation
    db_insert_into("Article_Category_Relation", "article_id, category_id", new_article["id"], primary_category_id)

    all_categories = db_get_all_equal("Category", "game_id", game_id)
    all_categories.each do |category| 
        # params[:"#{category["name"]}"] är om checkboxen för kategorin har värdet True eller nil
        if (params[:"#{category["name"]}"] == "True")
            db_insert_into("Article_Category_Relation", "article_id, category_id", new_article["id"], category["id"])
        end
        
    end
    redirect("/articles/#{new_article['id']}")
end

get("/articles/:id") do
    article_id = params[:id]

    if !is_integer_empty(article_id)
        redirect("/invalid")
    end

    @article = db_get_all_equal("Article", "id", article_id).first
    @game = db_get_all_equal("Game", "id", @article['game_id']).first
    @categories = db_get_categories_containing_article(article_id)
    
    slim(:"articles/show")
end

get("/articles/:id/edit") do
    article_id = params[:id]

    if !is_integer_empty(article_id)
        redirect("/invalid")
    end

    @article = db_get_all_equal("Article", "id", article_id).first
    @game = db_get_all_equal("Game", "id", @article['game_id']).first

    slim(:"articles/edit")
end

post("/articles/:id/update") do
    article_id = params[:id]
    new_title = params[:new_title]
    new_text = params[:new_text]

    if !is_integer_empty(article_id)
        redirect("/invalid")
    end

    db_update_two_condition("Article", "name", new_title, "text", new_text, "id", article_id)
    redirect("articles/#{article_id}")
end

post("/articles/:id/delete") do    
    article_id = params[:id]
    game_id = params[:game_id]

    if !is_integer_empty(article_id)
        redirect("/invalid")
    end

    db_delete("Article", "id", article_id)
    db_delete("Article_Category_Relation", "article_id", article_id)
    redirect("/games/#{game_id}")
end

# ----- Universal routes -----

get("/invalid") do
    slim(:invalid)
end

# ----- Methods -----

def delete_all_articles_in_category(category_id)
    all_articles = db_get_articles_in_category(category_id)
    all_articles.each do |article|
        article_belong_category_number = db_get_categories_containing_article(article["id"]).length

        if article_belong_category_number <= 1
            db_delete("Article", "id", article["id"])
        end

    end
end