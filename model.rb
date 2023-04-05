module Model
    require 'sqlite3'
    require 'bcrypt'

    #  ----- Databas -----

    # Connect to a database and results as hash
    #
    # @param [String] path, The path to the database
    #
    # @return [SQLite3::Database] the database
    def connect_to_db(path) 
        db = SQLite3::Database.new(path)
        db.results_as_hash = true
        return db
    end

    # Connect to a database and results as array
    #
    # @param [String] path, The path to the database
    #
    # @return [SQLite3::Database] the database
    def connect_to_db_array(path)
        db = SQLite3::Database.new(path)
        return db
    end

    # Connect to the main database and results as hash
    #
    # @return [SQLite3::Database] the database
    def connect_to_mdb()
        return connect_to_db("db/wiki.db")
    end

    # Connect to the main database and results as array
    #
    # @return [SQLite3::Database] the database
    def connect_to_mdb_array()
        return connect_to_db_array("db/wiki.db")
    end

    # ----- Select from database -----

    # Gets all attributes from a table
    #
    # @param [String] table, Table name
    #
    # @return [Hash] containing the data of all matching results
    def db_get_all(table)
        db = connect_to_mdb()
        return db.execute("SELECT * FROM #{table}")
    end

    # Gets all attributes from a table and orders the results in ascending order
    #
    # @param [String] table, Table name
    # @param [String] order_attribute, Which attribute to order by
    #
    # @return [Hash] containing the data of all matching results
    def db_get_all_order_asc(table, order_attribute)
        db = connect_to_mdb()
        return db.execute("SELECT * FROM #{table} ORDER BY #{order_attribute} ASC")
    end

    # Gets all attributes from a table, where an attribute should be equal to a variable
    #
    # @param [String] table, Table name
    # @param [String] compare_attribute, Which attribute to compare with
    # @param variable, The variable to compare an attribute with
    #
    # @return [Hash] containing the data of all matching results
    def db_get_all_equal(table, compare_attribute, variable) 
        db = connect_to_mdb()
        return db.execute("SELECT * FROM #{table} WHERE #{compare_attribute} = ?", variable)
    end

    # Gets all attributes from a table, where an attribute should be equal to a variable, and orders the results in ascending order
    #
    # @param [String] table, Table name
    # @param [String] compare_attribute, Which attribute to compare with
    # @param variable, The variable to compare an attribute with
    # @param [String] order_attribute, Which attribute to order by
    #
    # @return [Hash] containing the data of all matching results
    def db_get_all_equal_order_asc(table, compare_attribute, variable, order_attribute) 
        db = connect_to_mdb()
        return db.execute("SELECT * FROM #{table} WHERE #{compare_attribute} = ? ORDER BY #{order_attribute} ASC", variable)
    end

    # Gets one attribute from a table
    #
    # @param [String] table, Table name
    # @param [String] attribute, Which attribute to get
    #
    # @return [Hash] containing the data of all matching results
    def db_get_one(table, attribute)
        db = connect_to_mdb()
        return db.execute("SELECT #{attribute} FROM #{table}")
    end

    # Gets one attribute from a table, where an attribute should be equal to a variable
    #
    # @param [String] table, Table name
    # @param [String] attribute, Which attribute to get
    # @param variable, The variable to compare an attribute with
    #
    # @return [Hash] containing the data of all matching results
    def db_get_one_equal(table, attribute, compare_attribute, variable) 
        db = connect_to_mdb()
        return db.execute("SELECT #{attribute} FROM #{table} WHERE #{compare_attribute} = ?", variable)
    end

    # Gets all articles related to a specific category
    #
    # @param [Integer] category_id, The category's id
    #
    # @return [Hash] containing the data of all matching results
    def db_get_articles_in_category(category_id)
        db = connect_to_mdb()
        return db.execute("
            SELECT Article.*
            FROM Category
            INNER JOIN Article, Article_Category_Relation
            ON Category.id = Article_Category_Relation.category_id AND Article.id = Article_Category_Relation.article_id
            WHERE Category.id = ? ORDER BY Article.name ASC", category_id)
    end

    # Gets all categories related to a specific article 
    #
    # @param [Integer] article_id, The article's id
    #
    # @return [Hash] containing the data of all matching results
    def db_get_categories_containing_article(article_id)
        db = connect_to_mdb()
        return db.execute("
            SELECT Category.*
            FROM Article_Category_Relation
            INNER JOIN Category, Article
            ON Category.id = Article_Category_Relation.category_id AND Article.id = Article_Category_Relation.article_id
            WHERE Article.id = ?", article_id)
    end

    # ----- Insert into database -----

    # Inserts the value of one variable into one attribute
    #
    # @param [String] table, Table name
    # @param [String] attribute, Which attribute to insert into
    # @param variable, The variable to insert
    #
    # @return [nil] no return
    def db_insert_one_into(table, attribute, variable)
        db = connect_to_mdb()
        db.execute("INSERT INTO #{table} (#{attribute}) VALUES (?)", variable)
    end

    # Inserts the value of multiple variables into multiple attributes
    #
    # @param [String] table, Table name
    # @param [String] attributes, Which attributes to insert into
    # @param *variables, The variables to insert
    #
    # @return [nil] no return
    def db_insert_into(table, attributes, *variables)
        db = connect_to_mdb()

        question_marks = ""    
        variables.each do |variable|
            question_marks += " ?,"
        end
        question_marks = question_marks[0...-1]

        db.execute("INSERT INTO #{table} (#{attributes}) VALUES (#{question_marks})", variables)
    end

    # ----- Update database -----

    # Updates one attribute
    #
    # @param [String] table, Table name
    # @param [String] set_attribute, Which attribute to update
    # @param [String] set_variable, The variable which is used to update
    # @param [String] compare_attribute, The attribute used in the WHERE condition
    # @param [String] compare_variable, The variable used in the WHERE condition
    #
    # @return [nil] no return
    def db_update_condition(table, set_attribute, set_variable, compare_attribute, compare_variable)
        db = connect_to_mdb()
        db.execute("UPDATE #{table} SET #{set_attribute} = ? WHERE #{compare_attribute} = ?", set_variable, compare_variable)
    end

    # Updates two attributes
    #
    # @param [String] table, Table name
    # @param [String] set_attribute1, The first attribute to update
    # @param [String] set_variable1, The variable which is used to update the first attribute
    # @param [String] set_attribute1, The second attribute to update
    # @param [String] set_variable1, The variable which is used to update the second attribute
    # @param [String] compare_attribute, The attribute used in the WHERE condition
    # @param [String] compare_variable, The variable used in the WHERE condition
    #
    # @return [nil] no return
    def db_update_two_condition(table, set_attribute1, set_variable1, set_attribute2, set_variable2, compare_attribute, compare_variable)
        db = connect_to_mdb()
        db.execute("UPDATE #{table} SET #{set_attribute1} = ?, #{set_attribute2} = ? WHERE #{compare_attribute} = ?", set_variable1, set_variable2, compare_variable)
    end

    # ----- Delete from database -----

    # Deletes rows where an attribute is equal to a variable
    #
    # @param [String] table, Table name
    # @param [String] compare_attribute, The attribute used in the WHERE condition
    # @param variable, The variable to compare the attribute with
    #
    # @return [nil] no return
    def db_delete(table, compare_attribute, variable)
        db = connect_to_mdb_array()
        db.execute("DELETE FROM #{table} WHERE #{compare_attribute} = ?", variable)
    end

    #  ----- Valideringar -----

    # Validate whether a string is a whole number (integer) or empty
    #
    # @param [String] check_string, The variable to validate
    #
    # @return [Boolean] true if the variable is an integer or empty
    def is_integer_empty(check_string) 
        # kollar om det endast är siffror. Returnar true om strängen är tom eller en integer.
        return check_string.scan(/\D/).empty?
    end

    # Validate if the hash from a db get is empty
    #
    # @param [Hash] check, the result from a db select
    #
    # @return [Boolean] true if empty
    def db_select_is_empty(check)
        return check == nil
    end

    # Validate whether a string is empty
    #
    # @param [String] string
    #
    # @return [Boolean] true if empty
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

    # Validates if the username is unique
    #
    # @param [String] new_username, The username to validate
    #
    # @return [Boolean] true if the username is unique
    def is_username_unique(new_username)
        used_usernames = db_get_one("User", "name")
        used_usernames.each do |used_username|
            if used_username["name"] == new_username
                return false
            end
        end
        return true
    end

    # Validates if the user and password is not nil
    #
    # @param [Hash/String] user, The user data as a hash or the username as a string
    # @param [String] pass, The password
    #
    # @return [Boolean] true if the user and password is not nil
    def validate_user_and_pass(user, pass) 
        return user != nil && pass != nil
    end

    # Validates if the user has attempted to log in too many times in a short time
    #
    # @param [Array] cooldown_time, The recorded log in times
    # @param [Integer] attempts_given, The number of attempts given before a cooldown validation is done
    # @param [Integer] min_time_between_login, The mininum accepted time between each login attempt
    #
    # @return [Boolean] true if the user has not been too fast
    # @return [nil] if the user has not attempted to login enough times
    def cooldown_validation(cooldown_time, attempts_given, min_time_between_login)
        if cooldown_time.length >= attempts_given 
            if cooldown_time[1] - cooldown_time[0] <= min_time_between_login && cooldown_time[2] - cooldown_time[1] <= min_time_between_login
                return false # för snabba inloggningar
            end
            return true # ingen fara. 
        end
        return nil # inte testat tillräckligt många gånger än 
    end

    # Validates if the number of categories is of an acceptable number
    #
    # @param [Array] categories, Hashes of data for categories
    #
    # @return [Boolean] true if the number of categories is acceptable
    def validate_enough_categories_for_article(categories)
        if categories.length == 0
            return false
        else
            return true
        end
    end

    # Validates if the length of the text is acceptable
    #
    # @param [String] text, The text to validate
    #
    # @return [Boolean] true if acceptable length
    def validate_text_length(text)
        return text.length <= 100
    end

    # ----- BCrypt -----

    # Digests the password
    #
    # @param [String] password, The password to digest
    #
    # @return [BCrypt::Password] digested password
    def digest_password(password)
        return BCrypt::Password.create(password)
    end

    # Authentication: checks if the entered password is correct
    #
    # @param [String] password_digest, The digested password
    # @param [String] entered_password, The entered password
    #
    # @return [Boolean] true if they are matching
    def authentication(password_digest, entered_password)
        return BCrypt::Password.new(password_digest) == entered_password
    end

    # ----- Other -----

    # Registers a user if the entered passwords are matching
    #
    # @param [String] username, The entered username
    # @param [String] password, The first time writing the password
    # @param [String] password_confirm, The second time writing the password
    #
    # @return [Boolean] true if the passwords are matching
    def register_user(username, password, password_confirm)
        if password == password_confirm
            password_digested = digest_password(password)
            db_insert_into("User", "name, pw_digest", username, password_digested)
            return true
        else
            return false
        end
    end

end