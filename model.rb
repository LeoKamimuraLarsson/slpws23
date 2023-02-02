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

def db_get_equal(table, attribute, a, b) # a och b är sakerna som jämförs med varandra
    db = connect_to_mdb()
    return db.execute("SELECT #{attribute} FROM #{table} WHERE #{a} = #{b}")
end

def db_innerjoin_two(attribute1, attribute2, table1, table2, on1, on2, where1, where2)
    db = connect_to_mdb_array()
    return db.execute("SELECT #{attribute1}, #{attribute2} 
        FROM #{table1}
        INNER JOIN #{table2}
        ON #{on1} = #{on2}
        WHERE #{where1} = #{where2}")
end

# Insert into database

def db_insert_one_into(table, attribute, variable)
    db = connect_to_mdb()
    return db.execute("INSERT INTO #{table} (#{attribute}) VALUES (?)", variable)
end