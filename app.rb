require 'sinatra'
require 'sinatra/reloader'
require 'slim'
require_relative './model.rb'
enable :sessions
include Model

# Frågor:
# - är @param korrekt eller kolon framför?
#       - dynamiska har kolon


# Displays a register form
#
# @see #is_logged_in
get("/show_register") do
    if is_logged_in()
        redirect("/")
    end
    slim(:register)
end
 
# Registers a new user and redirects to either "/invalid" or "/show_login"
#
# @param [String] username, the entered username
# @param [String] password, the entered password
# @param [String] password_confirm, the repeated password
#
# @see #is_logged_in
# @see Model#validate_user_and_pass
# @see Model#is_empty
# @see Model#is_username_unique
# @see Model#register_user
post("/register") do
    if is_logged_in()
        redirect("/")
    end
    username = params[:username]
    password = params[:password]
    password_confirm = params[:password_confirm]

    # Validera så att username och password inte är nil, samt att username inte är endast mellanslag
    if !validate_user_and_pass(username, password) || is_empty(username)
        session[:error_msg] = "Invalid username or password"
        redirect("/invalid")
    end

    # Validering om username är unikt
    if !is_username_unique(username)
        session[:error_msg] = "The username is not unique"
        redirect("/invalid")
    end
    
    # Kolla password
    if register_user(username, password, password_confirm)
        redirect("/show_login")
    else
        session[:error_msg] = "The passwords does not match"
        redirect("/invalid")
    end
end

# Displays a login form
#
# @see #is_logged_in
get("/show_login") do
    if is_logged_in()
        redirect("/")
    end
    if session[:cooldown_tid] == nil
        session[:cooldown_tid] = []
    end
    @cooldown_time = session[:cooldown_tid]
    slim(:login)
end

# Attempts login and updates the session and redirects to "/games"
#
# @param [String] username, The username
# @param [String] password, The password
#
# @see #is_logged_in
# @see Model#db_get_all_equal
# @see Model#validate_user_and_pass
# @see Model#authentication
# @see Model#cooldown_validation
post("/login") do
    if is_logged_in()
        redirect("/")
    end
    attempts_given = 3
    min_time_between_login = 10
    username = params[:username]
    password = params[:password]

    user = db_get_all_equal("User", "name", username).first()  

    if (validate_user_and_pass(user, password))
        pw_digest = user["pw_digest"]
        user_id = user["id"]

        if (authentication(pw_digest, password))
            session[:id] = user_id
            session[:user] = username
            session[:cooldown_tid] = []
            redirect("/games")
        end
    end    

    # Cooldown validering
    session[:cooldown_tid] << Time.now.to_i
    redirect_route = "/show_login"
    cooldown_valid = cooldown_validation(session[:cooldown_tid], attempts_given, min_time_between_login)
    if cooldown_valid == false
        redirect_route = "/invalid"
        session[:error_msg] = "Too many login attempts at a short time"
    elsif cooldown_valid == nil
        redirect(redirect_route)
    end

    session[:cooldown_tid] = []
    redirect(redirect_route)
end

# The user log outs and redirects to "/games"
#
post('/logout') do
    session[:id] = nil
    session[:user] = nil
    redirect("/games")
end

# ----- Games -----

# Redirects to the main page "/games"
#
get("/") do
    redirect("/games")
end

# Displays all games
#
# @see Model#db_get_all_order_asc
get("/games") do 
    @games = db_get_all_order_asc("Game", "name")
    slim(:"games/index")
end 

# Creates a new game and redirects to "/"
#
# @param [String] name, The name of the new game
#
# @see #is_logged_in
# @see Model#is_empty
# @see Model#validate_text_length
# @see Model#db_insert_one_into
post("/games") do 
    if !is_logged_in()
        session[:error_msg] = "Access denied"
        redirect("/invalid")
    end
    name = params[:name]

    # kolla om namnet är tomt
    if (is_empty(name))
        session[:error_msg] = "Invalid name"
        redirect("/invalid")
    elsif !validate_text_length(name)
        session[:error_msg] = "The title is too long. (More than 100 characters)"
        redirect("/invalid")
    end

    db_insert_one_into("Game", "name", name)
    redirect("/")
end

# Displays one game and its categories
#
# @param [Integer] :id, The ID of the article
#
# @see Model#db_get_all_equal
# @see Model#db_select_is_empty
# @see Model#db_get_all_equal_order_asc
get("/games/:id") do 
    game_id = params[:id]
    @game = db_get_all_equal("Game", "id", game_id).first
    
    if db_select_is_empty(@game)
        session[:error_msg] = "404 Page Not Found"
        redirect("/invalid")
    end
        
    @categories = db_get_all_equal_order_asc("Category", "game_id", game_id, "name") 

    slim(:"games/show")
end

# Changes the name of one existing game and redirects to "/games/:id"
#
# @param [Integer] :id, The ID of the article
# @param [String] new_name, The new name of the article
#
# @see #is_admin
# @see Model#is_integer_empty
# @see Model#is_empty
# @see Model#validate_text_length
post("/games/:id/update") do
    if !is_admin()
        session[:error_msg] = "Access denied"
        redirect("/invalid")
    end
    game_id = params[:id]
    new_name = params[:new_name]

    if !is_integer_empty(game_id)
        redirect("/invalid")
    elsif (is_empty(new_name))
        session[:error_msg] = "Invalid title"
        redirect("/invalid")
    elsif !validate_text_length(new_name)
        session[:error_msg] = "The title is too long. (More than 100 characters)"
        redirect("/invalid")
    end

    db_update_condition("Game", "name", new_name, "id", game_id)
    redirect("/games/#{game_id}")
end

# Deletes one game and its categories and articles, and redirects to "/games"
#
# @param [Integer] :id, The ID of the article
#
# @see #is_admin
# @see #delete_all_articles_in_category
# @see Model#is_integer_empty
# @see Model#db_get_all_equal
# @see Model#db_delete
post("/games/:id/delete") do
    if !is_admin()
        session[:error_msg] = "Access denied"
        redirect("/invalid")
    end
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

# Creates a new category and redirects to "/games/#{game_id}"
#
# @param [String] name, The name of the new category
# @param [Integer] game_id, The id of the category's game
#
# @see #is_logged_in
# @see Model#is_empty
# @see Model#validate_text_length
# @see Model#db_insert_into
post("/categories") do
    if !is_logged_in()
        session[:error_msg] = "Access denied"
        redirect("/invalid")
    end
    name = params[:name]
    game_id = params[:game_id]

    # kolla om namnet är tomt
    if (is_empty(name))
        session[:error_msg] = "Invalid name"
        redirect("/invalid")
    elsif !validate_text_length(name)
        session[:error_msg] = "The title is too long. (More than 100 characters)"
        redirect("/invalid")
    end

    db_insert_into("Category", "name, game_id", name, game_id)
    redirect("/games/#{game_id}")
end

# Displays one category and its articles
#
# @params [Integer] :id, The category's id
#
# @see Model#db_get_all_equal
# @see Model#db_select_is_empty
# @see Model#db_get_articles_in_category
get("/categories/:id") do
    cat_id = params[:id]
    @category = db_get_all_equal("Category", "id", cat_id).first
    if db_select_is_empty(@category)
        session[:error_msg] = "404 Page Not Found"
        redirect("/invalid")
    end

    @articles = db_get_articles_in_category(cat_id)    
    
    game_id = @category["game_id"]
    @game = db_get_all_equal("Game", "id", game_id).first
    
    slim(:"categories/show")
end

# Changes the name of one existing category and redirects to "/categories/#{category_id}"
#
# @param [Integer] :id, The category's id
# @param [String] new_name, The new name for the category
#
# @see #is_admin
# @see Model#is_integer_empty
# @see Model#is_empty
# @see Model#validate_text_length
# @see Model#db_update_condition
post("/categories/:id/update") do
    if !is_admin()
        session[:error_msg] = "Access denied"
        redirect("/invalid")
    end
    category_id = params[:id]
    new_name = params[:new_name]

    if !is_integer_empty(category_id)
        redirect("/invalid")
    elsif (is_empty(new_name))
        session[:error_msg] = "Invalid title"
        redirect("/invalid")
    elsif !validate_text_length(new_name)
        session[:error_msg] = "The title is too long. (More than 100 characters)"
        redirect("/invalid")
    end

    db_update_condition("Category", "name", new_name, "id", category_id)
    redirect("/categories/#{category_id}")
end

# Deletes one category and all its articles, and redirects to "/games/#{game_id}"
#
# @param [Integer] :id, The category's id
# @param [Integer] game_id, The category's game's id
#
# @see #is_admin
# @see #delete_all_articles_in_category
# @see Model#is_integer_empty
# @see Model#db_delete
post("/categories/:id/delete") do
    if !is_admin()
        session[:error_msg] = "Access denied"
        redirect("/invalid")
    end
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

# Displays a form to create a new article
#
# @param [Integer] game_id, The article's game's id
# @param [Integer] category_id, The article's primary category's id
#
# @see #is_logged_in
# @see Model#db_get_all_equal
# @see Model#db_select_is_empty
# @see Model#db_get_all_equal_order_asc
get("/articles/new") do
    if !is_logged_in()
        session[:error_msg] = "Access denied"
        redirect("/invalid")
    end
    game_id = params[:game_id]
    category_id = params[:category_id]
    @game = db_get_all_equal("Game", "id", game_id).first
    @category = db_get_all_equal("Category", "id", category_id).first
    if db_select_is_empty(@game) || db_select_is_empty(@game)
        session[:error_msg] = "404 Page Not Found"
        redirect("/invalid")
    end
    @all_categories = db_get_all_equal_order_asc("Category", "game_id", game_id, "name")

    slim(:"articles/new")
end

# Creates a new article and redirects to "/articles/#{new_article['id']}"
#
# @param [Integer] game_id, The article's game's id
# @param [Integer] primary_category_id, The article's primary category's id
# @param [String] title, The article's title
# @param [String] text, The article's text
#
# @see #is_logged_in
# @see Model#is_empty
# @see Model#validate_text_length
# @see Model#db_insert_into
# @see Model#db_get_all_order_asc
# @see Model#db_get_all_equal
post("/articles") do 
    if !is_logged_in()
        session[:error_msg] = "Access denied"
        redirect("/invalid")
    end
    game_id = params[:game_id]
    primary_category_id = params[:primary_category_id]
    title = params[:new_title]
    text = params[:new_text]

    if (is_empty(title))
        session[:error_msg] = "Invalid title"
        redirect("/invalid")
    elsif !validate_text_length(title)
        session[:error_msg] = "The title is too long. (More than 100 characters)"
        redirect("/invalid")
    end

    # lägg till artikeln
    db_insert_into("Article", "name, text, game_id, user_id", title, text, game_id, session[:id])
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

# Displays one article 
#
# @param [Integer] :id, The article's id
#
# @see Model#db_get_all_equal
# @see Model#db_select_is_empty
# @see Model#db_get_categories_containing_article
get("/articles/:id") do
    article_id = params[:id]
    @article = db_get_all_equal("Article", "id", article_id).first

    if db_select_is_empty(@article)
        session[:error_msg] = "404 Page Not Found"
        redirect("/invalid")
    end
  
    @game = db_get_all_equal("Game", "id", @article['game_id']).first
    @categories = db_get_categories_containing_article(article_id)
    
    slim(:"articles/show")
end

# Displays a form to edit one existing article
# 
# @param [Integer] :id, The article's id
#
# @see #is_admin
# @see Model#is_author
# @see Model#db_get_all_equal
# @see Model#db_select_is_empty
# @see Model#db_get_categories_containing_article
get("/articles/:id/edit") do
    article_id = params[:id]
    if !is_author(article_id) && !is_admin()
        session[:error_msg] = "Access denied"
        redirect("/invalid")
    end    
    @article = db_get_all_equal("Article", "id", article_id).first

    if db_select_is_empty(@article)
        session[:error_msg] = "404 Page Not Found"
        redirect("/invalid")
    end
    
    @game = db_get_all_equal("Game", "id", @article['game_id']).first
    @related_categories = db_get_categories_containing_article(article_id)
    @all_categories = db_get_all_equal("Category", "game_id", @article['game_id'])

    slim(:"articles/edit")
end

# Updates one existing article and redirects to "articles/#{article_id}"
#
# @param [Integer] :id, The article's id
# @param [Integer] game_id, The article's game's id
# @param [String] new_title, The article's new title
# @param [String] new_text, The article's new text
#
# @see #is_admin
# @see Model#is_author
# @see Model#db_get_all_equal
# @see Model#is_empty
# @see Model#validate_text_length
# @see Model#validate_enough_categories_for_article
# @see Model#is_integer_empty
# @see Model#db_update_two_condition
# @see Model#db_delete
# @see Model#db_insert_into
post("/articles/:id/update") do
    article_id = params[:id]
    if !is_author(article_id) && !is_admin()
        session[:error_msg] = "Access denied"
        redirect("/invalid")
    end
    game_id = params[:game_id]
    new_title = params[:new_title]
    new_text = params[:new_text]

    new_category_relations = []
    all_categories = db_get_all_equal("Category", "game_id", game_id)
    all_categories.each do |category| 
        if (params[:"#{category["name"]}"] == "True")
           new_category_relations << category
        end       
    end

    # Valideringar
    if is_empty(new_title)
        session[:error_msg] = "Invalid title"
        redirect("/invalid")
    elsif !validate_text_length(new_title)
        session[:error_msg] = "The title is too long. (More than 100 characters)"
        redirect("/invalid")
    elsif !validate_enough_categories_for_article(new_category_relations)
        session[:error_msg] = "You must select at least one category"
        redirect("/invalid")
    elsif !is_integer_empty(article_id)
        redirect("/invalid")
    end

    # Update article
    db_update_two_condition("Article", "name", new_title, "text", new_text, "id", article_id)

    # Update article_category_relation
    db_delete("Article_Category_Relation", "article_id", article_id)
    new_category_relations.each do |category|
        db_insert_into("Article_Category_Relation", "article_id, category_id", article_id, category["id"])
    end    

    redirect("articles/#{article_id}")
end

# Deletes one article and its relations to categories, and redirects to "/games/#{game_id}"
#
# @param [Integer] :id, The article's id
# @param [Integer] game_id, The article's game's id
#
# @see #is_admin
# @see Model#is_author
# @see Model#is_integer_empty
# @see Model#db_delete
post("/articles/:id/delete") do   
    article_id = params[:id] 
    if !is_author(article_id) && !is_admin()
        session[:error_msg] = "Access denied"
        redirect("/invalid")
    end 
    game_id = params[:game_id]

    if !is_integer_empty(article_id)
        redirect("/invalid")
    end

    db_delete("Article", "id", article_id)
    db_delete("Article_Category_Relation", "article_id", article_id)
    redirect("/games/#{game_id}")
end

# ----- Universal routes -----

# Displays an error message
#
get("/invalid") do
    @error_msg = session[:error_msg]
    session[:error_msg] = nil
    slim(:invalid)
end

# ----- Methods -----

# Deletes all articles related to a category if they are not connected to any other category
#
# @param [Integer] category_id, The id of the category
#
# @return [nil] nothing.
def delete_all_articles_in_category(category_id)
    all_articles = db_get_articles_in_category(category_id)
    all_articles.each do |article|
        article_belong_category_number = db_get_categories_containing_article(article["id"]).length

        if article_belong_category_number <= 1
            db_delete("Article", "id", article["id"])
        end

    end
end

# Authorization: is the user logged in
#
# @return [Boolean]
def is_logged_in()
    return session[:id] != nil
end

# ----- Helpers -----

helpers do
    # Authorization: is the user the admin
    #
    # @return [Boolean]
    def is_admin()
        return session[:id] == 1
    end

    # Gets one user from the database
    #
    # @param [Integer] user_id, The user's id
    #
    # @return [Hash] containing all data of a user
    def get_user(user_id)
        return db_get_all_equal("User", "id", user_id).first()
    end

    # Authorization: is the user the the author of a article
    #
    # @param [Integer] article_id, The article's id
    #
    # @return [Boolean]
    def is_author(article_id)
        the_article = db_get_all_equal("Article", "id", article_id).first()
        if db_select_is_empty(the_article)
            return false
        end
        return the_article["user_id"] == session[:id]
    end
end