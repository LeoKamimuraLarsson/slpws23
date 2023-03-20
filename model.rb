require 'sqlite3'
require 'bcrypt'

#  ----- Databas -----

def connect_to_db(path) #hash return
    db = SQLite3::Database.new(path)
    db.results_as_hash = true
    return db
end

def connect_to_db_array(path) #array return
    db = SQLite3::Database.new(path)
    return db
end

def connect_to_mdb() # main database
    return connect_to_db("db/wiki.db")
end

def connect_to_mdb_array() # main database
    return connect_to_db_array("db/wiki.db")
end

# Select from database

def db_get_all(table)
    db = connect_to_mdb()
    return db.execute("SELECT * FROM #{table}")
end

def db_get_all_order_asc(table, order_attribute)
    db = connect_to_mdb()
    return db.execute("SELECT * FROM #{table} ORDER BY #{order_attribute} ASC")
end

def db_get_all_equal(table, compare_attribute, variable) 
    db = connect_to_mdb()
    return db.execute("SELECT * FROM #{table} WHERE #{compare_attribute} = ?", variable)
end

def db_get_all_equal_order_asc(table, compare_attribute, variable, order_attribute) 
    db = connect_to_mdb()
    return db.execute("SELECT * FROM #{table} WHERE #{compare_attribute} = ? ORDER BY #{order_attribute} ASC", variable)
end

def db_get_one(table, attribute)
    db = connect_to_mdb()
    return db.execute("SELECT #{attribute} FROM #{table}")
end

def db_get_one_equal(table, attribute, compare_attribute, variable) 
    db = connect_to_mdb()
    return db.execute("SELECT #{attribute} FROM #{table} WHERE #{compare_attribute} = ?", variable)
end

def db_get_articles_in_category(category_id)
    db = connect_to_mdb()
    return db.execute("
        SELECT Article.*
        FROM Category
        INNER JOIN Article, Article_Category_Relation
        ON Category.id = Article_Category_Relation.category_id AND Article.id = Article_Category_Relation.article_id
        WHERE Category.id = ? ORDER BY Article.name ASC", category_id)
end

def db_get_categories_containing_article(article_id)
    db = connect_to_mdb()
    return db.execute("
        SELECT Category.*
        FROM Article_Category_Relation
        INNER JOIN Category, Article
        ON Category.id = Article_Category_Relation.category_id AND Article.id = Article_Category_Relation.article_id
        WHERE Article.id = ?", article_id)
end

# Insert into database

def db_insert_one_into(table, attribute, variable)
    db = connect_to_mdb()
    db.execute("INSERT INTO #{table} (#{attribute}) VALUES (?)", variable)
end

def db_insert_into(table, attributes, *variables)
    db = connect_to_mdb()

    question_marks = ""    
    variables.each do |variable|
        question_marks += " ?,"
    end
    question_marks = question_marks[0...-1]

    db.execute("INSERT INTO #{table} (#{attributes}) VALUES (#{question_marks})", variables)
end

# Update database

def db_update_condition(table, set_attribute, set_variable, compare_attribute, compare_variable)
    db = connect_to_mdb()
    db.execute("UPDATE #{table} SET #{set_attribute} = ? WHERE #{compare_attribute} = ?", set_variable, compare_variable)
end

def db_update_two_condition(table, set_attribute1, set_variable1, set_attribute2, set_variable2, compare_attribute, compare_variable)
    db = connect_to_mdb()
    db.execute("UPDATE #{table} SET #{set_attribute1} = ?, #{set_attribute2} = ? WHERE #{compare_attribute} = ?", set_variable1, set_variable2, compare_variable)
end

# Delete from database

def db_delete(table, compare_attribute, variable)
    db = connect_to_mdb_array()
    db.execute("DELETE FROM #{table} WHERE #{compare_attribute} = ?", variable)
end

#  ----- Valideringar -----

def is_integer_empty(check_string) 
    # kollar om det endast är siffror. Returnar true om strängen är tom eller en integer.
    return check_string.scan(/\D/).empty?
end

def db_select_is_empty(check)
    return check == nil
end

def is_empty(string)
    work_string = string

    i = work_string.length - 1
    while work_string.length > 0
        if work_string[i] == " "
            work_string.chop!
        else
            break
        end
        i -= 1
    end

    return work_string.empty?
end

def is_username_unique(new_username)
    used_usernames = db_get_one("User", "name")
    used_usernames.each do |used_username|
        if used_username["name"] == new_username
            return false
        end
    end
    return true
end

def validate_user_and_pass(user, pass) 
    return user != nil && pass != nil
end

def cooldown_validation(cooldown_time, attempts_given, min_time_between_login)
    if session[:cooldown_tid].length >= attempts_given 
        if session[:cooldown_tid][1] - session[:cooldown_tid][0] <= min_time_between_login && session[:cooldown_tid][2] - session[:cooldown_tid][1] <= min_time_between_login
            return false # för snabba inloggningar
        end
        return true # ingen fara. 
    end
    return nil # inte testat tillräckligt många gånger än 
end

def validate_enough_categories_for_article(categories)
    if categories.length == 0
        return false
    else
        return true
    end
end

# ----- BCrypt -----

def digest_password(password)
    return BCrypt::Password.create(password)
end

def authentication(password_digest, entered_password)
    return BCrypt::Password.new(password_digest) == entered_password
end

# ----- Other -----

def register_user(username, password, password_confirm)
    if password == password_confirm
        password_digested = digest_password(password)
        db_insert_into("User", "name, pw_digest", username, password_digested)
        return true
    else
        return false
    end
end