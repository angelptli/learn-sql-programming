/* Handling Errors */

DROP TABLE IF EXISTS cookout_skewers;

-- Create a table to evenly distribute chicken skewers to cookout attendees
CREATE TABLE cookout_skewers (
    cookout_id TINYINT,
    chicken_skewers TINYINT,
    attendees TINYINT,
    skewer_per_attendee DECIMAL(6, 2)  
);

-- Additional view of table schema
DESCRIBE cookout_skewers;
/* Output:
+--------------------+-------------+------+-----+--------+------+
|Field               |Type         |Null  |Key  |Default |Extra |
+--------------------+-------------+------+-----+--------+------+
|cookout_id	         |tinyint      |YES	  |     |        |      |
+--------------------+-------------+------+-----+--------+------+
|chicken_skewers     |tinyint      |YES	  |     |        |      |
+--------------------+-------------+------+-----+--------+------+
|attendees	         |tinyint      |YES	  |     |        |      |
+--------------------+-------------+------+-----+--------+------+
|skewer_per_attendee |decimal(6,2) |YES	  |     |        |      |
+--------------------+-------------+------+-----+--------+------+ */

-- Create a division by zero handler. Demonstrate that it doesn't trigger when you're not dividing
-- by zero and it does when you do.
DROP PROCEDURE IF EXISTS insert_cookout_skewers;

DELIMITER $$

CREATE PROCEDURE insert_cookout_skewers (
    IN cookout_no TINYINT,
    IN skewers TINYINT,
    IN people TINYINT,
    IN skewer_per_person DECIMAL(6, 2)
)

BEGIN
    -- create conditions
    DECLARE divided_by_zero CONDITION FOR SQLSTATE '22012';
    DECLARE lacking_skewers CONDITION FOR SQLSTATE '45000';
    
    -- create a division by zero handler
    DECLARE CONTINUE HANDLER FOR divided_by_zero
    
    -- create a signal that sets more than 2 condition_information_item_name's
    SIGNAL divided_by_zero
        SET MESSAGE_TEXT = 'Division by zero / Denominator cannot be zero',
            MYSQL_ERRNO = 1365,
            CURSOR_NAME = 1; -- useless condition
    
    -- create a lacking skewers handler
    DECLARE CONTINUE HANDLER FOR lacking_skewers
    
    -- create signal for lack of skewers
    SIGNAL lacking_skewers
        SET MESSAGE_TEXT = 'Numerator less than denominator / Not enough chicken skewers for one per attendee';
    
    -- check if denominator is zero
    IF people = 0 THEN
        SIGNAL divided_by_zero;
        
    -- check if there are more chicken skewers than attendees; if numerator is more than denominator
    ELSEIF skewers < people THEN
        SIGNAL lacking_skewers;
        
    ELSE
        INSERT INTO cookout_skewers (cookout_id, chicken_skewers, attendees, skewer_per_attendee)
        VALUES (cookout_no, skewers, people, skewer_per_person);
        
        -- check how many chicken skewers each attendee with have
        SELECT
            cookout_id,
            skewer_per_attendee
        FROM cookout_skewers
        WHERE cookout_id = cookout_no;
        
    END IF;

END$$

DELIMITER ;

-- Call the stored procedure and trigger a division by zero error
CALL insert_cookout_skewers(1, 90, 0, (90/0));
/* Output: Error Code: 1365. Division by zero / Denominator cannot be zero
Explanation: The division by zero handled the error condition of denominator being zero */

-- Call the stored procedure without triggering a division by zero error
CALL insert_cookout_skewers(1, 90, 15, (90/15));
/* Output:
+------------+---------------------+
| cookout_id | skewer_per_attendee |
+------------+---------------------+
| 1          | 6.00                |
+------------+---------------------+

Explanation: All input values are valid. */

-- Call the stored procedure to raise lacking_skewers condition
CALL insert_cookout_skewers(2, 2, 15, (2/15));
/* Output: Error Code: 1644. Numerator less than denominator / Not enough chicken skewers for one per attendee
Explanation: It would be a sad cookout if there weren't at least one chicken skewer available per attendee.
             Also, if the numerator gets small (for example: 1 chicken skewer) and the number of attendees aka
             denominator is much larger (for example: 15 attendees), then it would not make sense to divide
             1 chicken skewer amoung 15 attendees because they would receive super small pieces of chicken.*/

-- Reraise the division by zero error
CALL insert_cookout_skewers(2, 90, 0, (90/0));
/* Output: Error Code: 1365. Division by zero / Denominator cannot be zero
Explanation: */

-- View table data
SELECT * FROM cookout_skewers;
/* Output:
+-----------+-----------------+-----------+---------------------+
|cookout_id | chicken_skewers | attendees | skewer_per_attendee |
+-----------+-----------------+-----------+---------------------+
| 1         | 90              | 15        | 6.00                |
+-----------+-----------------+-----------+---------------------+ */