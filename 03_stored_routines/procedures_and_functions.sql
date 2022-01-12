USE practice;

-- GOAL: Create 1 stored procedures and 1 function which both do the same thing... 

/* Create table with 2 columns, one primary key with auto-index and the other a numerical
data type */
DELIMITER $$
DROP TABLE IF EXISTS wallet;

CREATE TABLE wallet (
	id INT PRIMARY KEY AUTO_INCREMENT,
    spare_change DECIMAL(6,2))$$
DELIMITER ;

-- Stored Procedures
DELIMITER //
DROP PROCEDURE IF EXISTS mula;

CREATE PROCEDURE mula (deposit_1 DECIMAL(6,2), deposit_2 DECIMAL(6,2))
BEGIN
	INSERT INTO wallet (spare_change)
    VALUES (deposit_1), (deposit_2), (deposit_1 + deposit_2);
  
	SELECT SUM(spare_change)
	FROM wallet
	WHERE spare_change = deposit_1 OR spare_change = deposit_2;
END//
DELIMITER ;

CALL mula (1.55, 2.44);
/* Output
+------------------+
|SUM(spare_change) |
+------------------+
|3.99              |
+------------------+
Explanation: The result of passing the parameter values 1.55 and 2.44 into this
stored procedure is 3.99. This result is displayed via the SELECT statement in
the stored procedures. This sum has been inserted into the table's third row.*/

-- Display table
SELECT * FROM wallet;
/* Output
+----+-------------+
|id  |spare_change |
+----+-------------+
|1   |1.55         |
+----+-------------+
|2   |2.44         |
+----+-------------+
|3   |3.99         |
+----+-------------+ */

-- Function equivalent
DELIMITER $$
DROP FUNCTION IF EXISTS save_up;

CREATE FUNCTION save_up (save_1 DECIMAL(6,2), save_2 DECIMAL(6,2))
RETURNS DECIMAL(6,2) DETERMINISTIC
BEGIN
	INSERT INTO wallet (spare_change)
    VALUES (save_1), (save_2), (save_1 + save_2);
    
    RETURN save_1 + save_2;
END$$
DELIMITER ;

SELECT save_up (1.55, 2.44);
/* Output
+---------------------+
|save_up (1.55, 2.44) |
+---------------------+
|3.99                 |
+---------------------+
Explanation: The resulting value is from the RESULT statement, which
added the two parameter values 1.55 and 2.44, resulting in 3.99.
This result has been inserted into the table's third row.*/

/* Questions:
Did you create a procedure or a function? Why did you choose one over the other?
Explain the differences between procedures and functions.

Answers:
I created both. I prefer the stored functions because it is more concise.
A difference was that stored procedures required a select statement as one
of its procedures to display the result while the stored functions required
return statements to return the result. Stored procedures uses CALL to execute
the stored procedures while stored functions uses SELECT. Stored functions
must return a value or result  to caller while stored procedures does not need to. */