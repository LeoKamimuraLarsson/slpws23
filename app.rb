require 'sinatra'
require 'sinatra/reloader'
require 'slim'
require 'sqlite3'
require 'bcrypt'
enable :sessions

# global variables
main_db = "db/wiki.db"

# routes

get("/") do
    redirect("/games")
end

get("/games") do # visa alla spel
    db = connect_to_db(main_db)
    @games = db.execute("SELECT * FROM Game")
    slim(:"games/index")
end 

post("/games") do # lägg nytt spel
    name = params[:name]
    db = connect_to_db(main_db)
    db.execute("INSERT INTO Game (name) VALUES (?)", name)
    redirect("/")
end

get("/games/:id") do # visa ett spel
    #game_id = params[:id]
    db = connect_to_db(main_db)
    @result = db.execute("
        SELECT Game.name, Category.* 
        FROM Game
        INNER JOIN Category
        ON Game.id = Category.game_id")
    p @result
    slim(:"games/show")
end


# methods

def connect_to_db(path)
    db = SQLite3::Database.new(path)
    db.results_as_hash = true
    return db
end