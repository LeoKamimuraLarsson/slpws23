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

    @game = db_get_equal("Game", "name", "id", game_id).first
    @categories = db_get_equal("Category", "*", "game_id", game_id)

    slim(:"games/show")
end
