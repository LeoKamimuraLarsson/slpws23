require 'sinatra'
require 'sinatra/reloader'
require 'slim'
require 'bcrypt'
require_relative './model.rb'
enable :sessions

# routes

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

    db_insert_one_into("Game", "name", name)
    redirect("/")
end

get("/games/:id") do # visa ett spel
    game_id = params[:id]
    
    #@result = db_innerjoin_two("Game.name", "Category.*", "Game", "Category", "Game.id", "Category.game_id", "Game.id", game_id)
    
    @game = db_get_all_equal("Game", "id", game_id).first
    @categories = db_get_all_equal_order_asc("Category", "game_id", game_id, "name") 

    slim(:"games/show")
end

post("/games/:id/update") do
    game_id = params[:id]
    new_name = params[:new_name]

    db_update_condition("Game", "name", new_name, "id", game_id)
    #db_update_condition("Game", "name = \'#{new_name}\'", "id = #{game_id}")
    redirect("/games/#{game_id}")
end

post("/games/:id/delete") do
    game_id = params[:id]
    db_delete("Game", "id", game_id)
    redirect("/games")
end

# ----- Categories -----

post("/categories") do # lägg till ny kategori
    name = params[:name]
    game_id = params[:game_id]

    # kolla om namnet är tomt

    db_insert_into("Category", "name, game_id", name, game_id)
    redirect("/games/#{game_id}")
end

get("/categories/:id") do
    cat_id = params[:id]

    @articles = db_get_articles_in_category(cat_id)
    @category = db_get_all_equal("Category", "id", cat_id).first
    
    game_id = @category["game_id"]
    @game = db_get_all_equal("Game", "id", game_id).first
    
    slim(:"categories/show")
end

post("/categories/:id/update") do
    category_id = params[:id]
    new_name = params[:new_name]

    db_update_condition("Category", "name", new_name, "id", category_id)
    redirect("/categories/#{category_id}")
end

post("/categories/:id/delete") do
    category_id = params[:id]
    game_id = params[:game_id]
    db_delete("Category", "id", category_id)
    redirect("/games/#{game_id}")
end

# ----- Articles -----

get("/articles/:id") do
    article_id = params[:id]
    @article = db_get_all_equal("Article", "id", article_id).first
    @game = db_get_all_equal("Game", "id", @article['game_id']).first
    @categories = db_get_categories_containing_article(article_id)
    
    slim(:"articles/show")
end

get("/articles/:id/edit") do
    article_id = params[:id]
    @article = db_get_all_equal("Article", "id", article_id).first
    @game = db_get_all_equal("Game", "id", @article['game_id']).first

    slim(:"articles/edit")
end