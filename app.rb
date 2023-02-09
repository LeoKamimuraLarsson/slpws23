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
    @games = db_get_all("Game")
    slim(:"games/index")
end 

post("/games") do # lägg nytt spel
    name = params[:name]
    db_insert_one_into("Game", "name", name)
    redirect("/")
end

get("/games/:id") do # visa ett spel
    game_id = params[:id]
    
    #@result = db_innerjoin_two("Game.name", "Category.*", "Game", "Category", "Game.id", "Category.game_id", "Game.id", game_id)
    
    @game = db_get_condition("Game", "*", "id = #{game_id}").first
    @categories = db_get_condition("Category", "*", "game_id = #{game_id}") # ändra condition. vill inte ha någon sql kod.

    slim(:"games/show")
end

post("/games/:id/update") do
    game_id = params[:id]
    new_name = params[:new_name]

    db_update_condition("Game", "name = \'#{new_name}\'", "id = #{game_id}")
    redirect("/games/#{game_id}")
end

post("/games/:id/delete") do
    game_id = params[:id]
    db_delete("Game", "id = #{game_id}")
    redirect("/games")
end

post("/category") do # lägg till ny kategori
    name = params[:name]

    # problem!!! behöver spelets id!!!

    db_insert_one_into("Category", "name", name)
    redirect("/")
end