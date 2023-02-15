require 'sqlite3'

# Methods

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

def db_get_all_equal(table, compare_attribute, variable) 
    db = connect_to_mdb()
    return db.execute("SELECT * FROM #{table} WHERE #{compare_attribute} = ?", variable)
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
        WHERE Category.id = ?", category_id)
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

# Delete from database

def db_delete(table, compare_attribute, variable)
    db = connect_to_mdb_array()
    db.execute("DELETE FROM #{table} WHERE #{compare_attribute} = ?", variable)
end