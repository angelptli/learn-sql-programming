-- Prepared Statements

/*
First two tasks:

1. Create a prepared statement in a stored procedure which uses a parameter to the stored procedure
   in the prepared statement.
   - What happens if you don't "DEALLOCATE PREPARE" and then call the procedure multiple times.
   - Try to create a prepared statement in one function/procedure and use it in another. What happens?
2. Create a prepared statement which uses variable substitution in the EXECUTE statement.
*/


-- This stored procedure returns a string about dinner food and contains a prepared statement
DELIMITER $$

CREATE PROCEDURE whats_for_dinner (food1 VARCHAR(35), food2 VARCHAR(35))
BEGIN
    -- This uses variable substitution
    SET @foodstring = "SELECT CONCAT(?, ' and ', ?, ' for dinner') AS for_dinner";
    SET @food1 = food1;
    SET @food2 = food2;
    
    PREPARE foodstmt FROM @foodstring;
    EXECUTE foodstmt USING @food1, @food2;
    -- Test without "DEALLOCATE PREPARE"
END$$

DELIMITER ;


-- Call the stored procedure multiple times
CALL whats_for_dinner('Tuna', 'pasta');
/*
+----------------------------+
| for_dinner                 |
+----------------------------+
| Tuna and pasta for dinner  |
+----------------------------+

I called the stored procedure 70 times and didn't experience any slowing. The duration varied from
0.000, 0.015, and 0.016 sec. The effect is not clear on a surface level but from reading the
articles and documentation, I know that not doing "DEALLOCATE PREPARE" will add up the memory used
upon each call to the stored procedure. If max_prepared_stmt_count had a low limit like 30, then I
wouldn't be able to call after my 30th call and would have to use "DEALLOCATE PREPARE" to deallocate.
*/


-- Create another stored procedure to attempt to use the prepared statement above as an input variable
-- This stored procedure returns a string about dessert food
DELIMITER $$

CREATE PROCEDURE whats_for_dessert (dessert1 VARCHAR(35), dessert2 VARCHAR(35))
BEGIN
    SET @dessert1 = dessert1;
    SET @dessert2 = dessert2;
    
    -- Use prepared statement from whats_for_dinner stored procedure
    EXECUTE foodstmt USING @dessert1, @dessert2;
    -- Test without "DEALLOCATE PREPARE"
END$$

DELIMITER ;


CALL whats_for_dessert('Seaweed', 'plankton');
/*
+----------------------------------+
| for_dessert                      |
+----------------------------------+
| Seaweed and plankton for dinner  |
+----------------------------------+

Quite unexpected, what kind of sorcery is this? I was able to use a prepared statement from one
stored procedure in another probably because I did not use "DEALLOCATE PREPARE" earlier. Also,
this is not what I want for dessert obviously!
*/


-- Now I deallocate the prepared statement to see what happens
DEALLOCATE PREPARE foodstmt;


-- Call the stored procedure whats_for_dessert again
CALL whats_for_dessert('Seaweed', 'plankton');
/*
Result:
Error Code: 1243. Unknown prepared statement handler (foodstmt) given to EXECUTE

Now I know that if I don't do "DEALLOCATE PREPARE", I could use a prepared statement in another
stored procedure.
*/

-- ////////////////////////////////////////////////////////////////////////////////////////////////////

/*
Third Task:

3. Create and use a prepared statement. Do not DEALLOCATE PREPARE the statement. Then close your
   mysql session, and open a new one. Try to use your prepared statement. What happens?
*/


-- Create and use a prepared statement (this returns a string about a desirable pet)
PREPARE pet_stmt FROM "SELECT CONCAT('I want a ', ?, ' as a pet') AS pet_wish";
SET @pet = 'salmon';
EXECUTE pet_stmt USING @pet;
/*
+---------------------------+
| pet_wish                  |
+---------------------------+
| I want a salmon as a pet  |
+---------------------------+
*/


-- I exit close my mysql session ...
-- ...
-- Now I'm back in a new session and try to execute the prepared statement pet_stmt
EXECUTE pet_stmt USING @pet;
/*
Result:
Error Code: 1243. Unknown prepared statement handler (pet_stmt) given to EXECUTE

This error occurred because once I ended my session, the prepared statement ceased to exist. I would
need to prepare the statement again and again in each new session to use the prepared statement.
*/

-- ////////////////////////////////////////////////////////////////////////////////////////////////////

/*
Fourth task:

4. Can you use prepared statements in transactions?
*/


-- Let's see if a transaction containing a prepared statement can work. I'll see if it can rollback
-- a variable assignment
SET @wild_pet = 'bear';


-- Test prepared statement in a transaction
START TRANSACTION;

-- prepared statement about a desirable wild pet
PREPARE pet_stmt_2 FROM "SELECT CONCAT('I want a ', ?, ' as a pet') AS pet_wish";
SET @wild_pet = 'raccoon';
EXECUTE pet_stmt_2 USING @wild_pet;
/*
+----------------------------+
| pet_wish                   |
+----------------------------+
| I want a raccoon as a pet  |
+----------------------------+
*/
DEALLOCATE PREPARE pet_stmt_2;

-- Attempt rollback
ROLLBACK;


-- Check if transaction worked and @pet rolled back to equal 'bear'
SELECT @wild_pet;
/*
+------------+
| @wild_pet  |
+------------+
| raccoon    |
+------------+

The rollback didn't work. It couldn't roll back the new variable assignment.
*/


-- Check if variable assignments can be roll backed
SET @wild_pet = 'bear';


START TRANSACTION;
SET @wild_pet = 'raccoon';
ROLLBACK;


SELECT @wild_pet;
/*
+------------+
| @wild_pet  |
+------------+
| raccoon    |
+------------+

Unsuccessful rollback of changed variable assignment.
*/


-- Use fruits table to check if prepared statements can work in transactions
CREATE TABLE fruits (
    fruit_id TINYINT NOT NULL AUTO_INCREMENT,
    fruit_name VARCHAR(35) NOT NULL,
    PRIMARY KEY (fruit_id)
);


INSERT INTO fruits (fruit_name)
VALUES ('strawberry'), ('mango');


-- View original state of fruits table
SELECT * FROM fruits;
/*
+-----------+-------------+
| fruit_id  | fruit_name  |
+-----------+-------------+
| 1         | strawberry  |
+-----------+-------------+
| 2         | mango       |
+-----------+-------------+
*/


-- Create transaction containing prepared statement that updates the fruits table
START TRANSACTION;

PREPARE update_stmt FROM 'UPDATE fruits SET fruit_name=? WHERE fruit_id = 2';
SET @new_fruit = 'jackfruits';                   
EXECUTE update_stmt USING @new_fruit;
DEALLOCATE PREPARE update_stmt;

-- Attempt rollback
ROLLBACK;


-- View fruits table
SELECT * FROM fruits;
/*
+-----------+-------------+
| fruit_id  | fruit_name  |
+-----------+-------------+
| 1         | strawberry  |
+-----------+-------------+
| 2         | mango       |
+-----------+-------------+

Successful roll back of update from prepared statement. So there are times prepared statements
work in transactions, as long as it doesn't have anything that causes an implicit commit.
*/

-- ////////////////////////////////////////////////////////////////////////////////////////////////////