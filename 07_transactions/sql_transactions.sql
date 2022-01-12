-- Working with Transactions

-- Creating a table and inserting 1 million rows:
-- This table will record the christmas discount amount each member is entitled to every time
-- they eat at "XXXX Fancy Buffet Restaurant" around christmas time.

CREATE TABLE members_discount (
    member_id MEDIUMINT NOT NULL AUTO_INCREMENT,
    christmas_discount TINYINT UNSIGNED NOT NULL DEFAULT 0,
    member_status ENUM('Premium','Regular') NOT NULL DEFAULT 'Regular',
    PRIMARY KEY (member_id)
);


/*
Make the members_discount tables have 1 million rows aka 1 million members:
I could use this procedure but I used filldb instead because this procedure inserts
only ~13K rows before losing connection (Error Code: 2013...). I want all rows with the
default value 0 for the christmas_discount column.

DELIMITER $$

CREATE PROCEDURE generate_member_id()
BEGIN
    DECLARE n INT DEFAULT 0;
    WHILE n < 1000000 DO
        INSERT INTO members_discount (member_id)
        VALUES (DEFAULT);
        SET n = n + 1;
    END WHILE;
END$$

DELIMITER ;

CALL generate_member_id();
*/


-- Assign "Premium" to member_status for roughly 50% of members
UPDATE members_discount
SET member_status = 'Premium'
WHERE RAND() < 0.5;

-- Out of the 1 million members, 498,904 are "Premium" members
SELECT COUNT(member_status)
FROM members_discount
WHERE member_status = 'Premium';


-- Original state of members_discount table
SELECT *
FROM members_discount
LIMIT 5;
/*
+------------+---------------------+----------------+
| member_id  | christmas_discount  | member_status  |
+------------+---------------------+----------------+
| 1          | 0                   | Regular        |
+------------+---------------------+----------------+
| 2          | 0                   | Regular        |
+------------+---------------------+----------------+
| 3          | 0                   | Regular        |
+------------+---------------------+----------------+
| 4          | 0                   | Regular        |
+------------+---------------------+----------------+
| 5          | 0                   | Premium        |
+------------+---------------------+----------------+
*/

-- //////////////////////////////////////////////////////////////////////////////////////////

/*
From Instructions:

Make a transaction which changes a million or more rows of data.
- In one case, roll back without commit the changes
- In one case, commit the changes
- In another case, alter the table, then change some data in one row, then rollback
  the transaction.
*/


-- Roll back without commiting the changes:

START TRANSACTION;
    
-- Update "Premium" members with a $5 discount
UPDATE members_discount
SET christmas_discount = 5
WHERE member_status = 'Premium';
    
-- Update "Regular" members with a $1 discount
UPDATE members_discount
SET christmas_discount = 1
WHERE member_status = 'Regular';

-- ROLLBACK Duration: 10.609 sec <- Expected. Takes time to rollback 1 million rows.
ROLLBACK;


-- Commit the changes (in the transaction):
START TRANSACTION;
    
-- Update "Premium" members with a $5 discount
UPDATE members_discount
SET christmas_discount = 5
WHERE member_status = 'Premium';
    
-- Update "Regular" members with a $1 discount
UPDATE members_discount
SET christmas_discount = 1
WHERE member_status = 'Regular';

-- COMMIT Duration: 0.063 sec <- Expected. It's fast, it commits.
COMMIT; 


-- View the committed changes
SELECT *
FROM members_discount
LIMIT 5;
/*
+------------+---------------------+----------------+
| member_id  | christmas_discount  | member_status  |
+------------+---------------------+----------------+
| 1          | 1                   | Regular        |
+------------+---------------------+----------------+
| 2          | 1                   | Regular        |
+------------+---------------------+----------------+
| 3          | 1                   | Regular        |
+------------+---------------------+----------------+
| 4          | 1                   | Regular        |
+------------+---------------------+----------------+
| 5          | 5                   | Premium        |
+------------+---------------------+----------------+
*/


-- Alter the table, then change some data in one row, then rollback the transaction:

START TRANSACTION;

-- Alter table by changing column name from christmas_discount to xmas_disc
ALTER TABLE members_discount
CHANGE christmas_discount xmas_disc TINYINT UNSIGNED NOT NULL DEFAULT 0;

-- Update a random row to change member_status from "Premium" to "Regular"
UPDATE members_discount
SET member_status = 'Regular'
WHERE member_id = 1000;

-- Duration: 0.00 sec <- Understandable. I expected it to only undo two small changes.
ROLLBACK;


-- However, check if the changes were rolled back
SELECT *
FROM members_discount
WHERE member_id = 1000;
/*
+------------+------------+----------------+
| member_id  | xmas_disc  | member_status  |
+------------+------------+----------------+
| 1000       | 1          | Regular        |
+------------+------------+----------------+
The rollback unexpectedly failed and didn't undo the changes. The reason is because an ALTER
cannot be rolled back and also causes an implicit commit.
*/

-- //////////////////////////////////////////////////////////////////////////////////////////

/*
From Instructions:

Make a transaction which alters data (inserts, deletes, updates) in more than one table.
Alter one of the tables, then try to roll back the transaction.
*/


-- Create another table called annual_eatoff:
-- This table records the number of breadsticks each contestant consumed in the buffet's
-- breadstick eat-off. This table will have 25 rows inserted.

CREATE TABLE annual_eatoff (
    contestant_id TINYINT NOT NULL AUTO_INCREMENT,
    member_id MEDIUMINT UNSIGNED NOT NULL,
    breadstick_no TINYINT UNSIGNED NOT NULL DEFAULT 0,
    yr YEAR NOT NULL,
    PRIMARY KEY (contestant_id)
);


-- Make a transaction which alters data (inserts, deletes, updates) in more than one table.
-- Alter one of the tables, then try to roll back the transaction.

START TRANSACTION;

-- Insert a record for the newest "Regular" member into the members_discount table
INSERT INTO members_discount
VALUES (DEFAULT, 1, 'Regular');

-- Insert 25 records of contestants into the annual_eatoff table
INSERT INTO annual_eatoff (member_id, breadstick_no, yr)
VALUES
    (455000, 15, 2013), (51511, 18, 2013), (511, 5, 2013), (823542, 22, 2013), (444444, 11, 2013), 
    (546151, 30, 2014), (1000000, 15, 2014), (61616, 15, 2014), (11111, 8, 2014), (5, 11, 2014), 
    (2121, 20, 2015), (662, 33, 2015), (61688, 7, 2015), (8484, 8, 2015), (2, 16, 2015), 
    (9848, 7, 2016), (521, 7, 2016), (400000, 9, 2016), (11, 19, 2016), (984, 14, 2016), 
    (5555, 20, 2017), (6464, 18, 2017), (222151, 35, 2017), (200121, 8, 2017), (555484, 40, 2017);

-- Delete the latest "Regular" member from the members_discount table
DELETE FROM members_discount
ORDER BY member_id DESC
LIMIT 1;

-- Delete the latest record from the annual_eatoff
DELETE FROM annual_eatoff
ORDER BY contestant_id DESC
LIMIT 1;

-- Update the members_discount table to upgrade member_id 1000 to "Premium" status
UPDATE members_discount
SET member_status = 'Premium'
WHERE member_id = 1000;

-- Update the annual_eatoff to change member_id 200121 to have 40 in the breadstick_no column
UPDATE annual_eatoff
SET breadstick_no = 40
WHERE member_id = 200121;

-- Alter the members_discount table to change xmas_disc column name back to christmas_discount
ALTER TABLE members_discount
CHANGE xmas_disc christmas_discount TINYINT UNSIGNED NOT NULL DEFAULT 0;

-- ROLLBACK Duration: 0.000 sec. <- Unexpected, but understandable. It's the ALTER causing
-- an implicit commit.
ROLLBACK;


-- See that none of the changes were rolled back
SELECT MAX(contestant_id)
FROM annual_eatoff;
/* 
+---------------------+
| MAX(contestant_id)  |
+---------------------+
| 24                  |
+---------------------+

If the rollback worked, there shouldn't have been any inserted rows in annual_eatoff and
neither would there be a last record (25th row) deleted from the table. 
*/


SELECT *
FROM members_discount
WHERE member_id = 1000;
/*
+------------+------------+----------------+
| member_id  | xmas_disc  | member_status  |
+------------+------------+----------------+
| 1000       | 1          | Premium        |
+------------+------------+----------------+

Without a successful rollback, member_id 1000 gets updated to "Premium" member_status.
It should've been "Regular" if the rollback were successful. But again, the last ALTER
statement caused an implicit commit for all the statements in the transaction.
*/

-- //////////////////////////////////////////////////////////////////////////////////////////

/*
From Instructions:

Make one function or procedure which implements changes in a transaction.  Perhaps update
one of your previous once and make it more effective using transactions.
*/


-- I update the members_discount table to reset all christmas_discount values to 0.
-- I'll make the same updates early in a stored procedure
UPDATE members_discount
SET christmas_discount = 0
WHERE member_id > 0;

-- Back to original state of members_discount table
SELECT *
FROM members_discount
LIMIT 5;
/*
+------------+---------------------+----------------+
| member_id  | christmas_discount  | member_status  |
+------------+---------------------+----------------+
| 1          | 0                   | Regular        |
+------------+---------------------+----------------+
| 2          | 0                   | Regular        |
+------------+---------------------+----------------+
| 3          | 0                   | Regular        |
+------------+---------------------+----------------+
| 4          | 0                   | Regular        |
+------------+---------------------+----------------+
| 5          | 0                   | Premium        |
+------------+---------------------+----------------+
*/


-- Use procedure to insert $5 discount for "Premium" members and $1 for "Regular" members
DELIMITER $$

CREATE PROCEDURE update_discount (premium_disc TINYINT, regular_disc TINYINT)
BEGIN
    DECLARE _rollback BOOL DEFAULT 0;
    DECLARE CONTINUE HANDLER FOR SQLEXCEPTION SET _rollback = 1;

    START TRANSACTION;
    
    -- Update "Premium" members with a $5 discount
    UPDATE members_discount
    SET christmas_discount = premium_disc
    WHERE member_status = 'Premium';
    
    -- Update "Regular" members with a $1 discount
    UPDATE members_discount
    SET christmas_discount = regular_disc
    WHERE member_status = 'Regular';

    IF _rollback THEN
        ROLLBACK;
    ELSE
        COMMIT;
    END IF;

END$$

DELIMITER ;


-- This will ROLLBACK since christmas_discount has a TINYINT UNSIGNED data type
CALL update_discount(-5, 1);
/*
ROLLBACK Duration: 21.078 sec

Wow, quite unexpected because it takes approximately double amount of the time to rollback
compared to the rollback early. However, I have to take into consideration that a portion
of the time is from the two update statements included in the transaction. Using a stored
procedure makes it easier in the sense of running one call statement on the procedure as
opposed to running each statement in a transaction, which can be tedious and difficult to
maintain. The stored procedure also allows exception handling and conditional statements
to help ensure ACID compliance is held up.
*/


-- This will COMMIT the updates
CALL update_discount(5, 1);
/*
ROLLBACK Duration: 19.000 sec

This is an expected result for the same reasons why the rollback above looks like it took
more time to execute versus the one early. This duration time includes the time of the two
update statements.
*/

-- //////////////////////////////////////////////////////////////////////////////////////////

/*
From Instructions:

If you can, run two sessions. While you're running a long running transaction, try to
update info in the same table. What happens when you try to update? What happens when
your transaction commits?

Answer:
While session 1 is running the long transaction, I am unable to make any update or changes
from session 2. I have to wait for session 1 to finish its transaction before attempting to
update from session 2.
*/

-- //////////////////////////////////////////////////////////////////////////////////////////