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

def db_get_one(table, attribute)
    db = connect_to_mdb()
    return db.execute("SELECT #{attribute} FROM #{table}")
end

def db_get_condition(table, attribute, condition) # a och b är sakerna som jämförs med varandra
    db = connect_to_mdb()
    return db.execute("SELECT #{attribute} FROM #{table} WHERE #{condition}")
end

def db_innerjoin_two(attribute1, attribute2, table1, table2, on, where)
    db = connect_to_mdb_array()
    return db.execute("SELECT #{attribute1}, #{attribute2} 
        FROM #{table1}
        INNER JOIN #{table2}
        ON #{on}
        WHERE #{where}")
end

# Insert into database

def db_insert_one_into(table, attribute, variable)
    db = connect_to_mdb()
    db.execute("INSERT INTO #{table} (#{attribute}) VALUES (?)", variable)
end

#def db_insert_two_into(table, attributes, variable1, varable2)
#    db = connect_to_mdb()
#    db.execute("INSERT INTO #{table} (#{attributes}) VALUES (?, ?)", variable1, varable2)
#end

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

def db_update_condition(table, set, condition)
    db = connect_to_mdb()
    db.execute("UPDATE #{table} SET #{set} WHERE #{condition}")
end

# Delete from database

def db_delete(table, condition)
    db = connect_to_mdb_array()
    db.execute("DELETE FROM #{table} WHERE #{condition}")
end