USE practice;

CREATE TABLE subway_sub_exp (
	sub_id INT NOT NULL AUTO_INCREMENT,
	quantity TINYINT NULL,
    bread CHAR(30) NULL,
    meat VARCHAR(20) NULL,
    price_decimal DECIMAL(6,3) NULL,
    price_float FLOAT NULL,
    bread_quality ENUM('normal', 'underbaked', 'burnt', 'toasted', 'dry', 'soggy') NULL,
    experience SET('fine', 'good', 'bad', 'dreadful') NULL,
    purchase_date DATE NULL,
    purchase_time TIME NULL,
    purchase_dt DATETIME NULL,
    PRIMARY KEY(sub_id));

/* ============================================================
						QUESTION 1
For TINYINT set 1 value to -128 and one to 127.
What happens if you try to decrement/increment these values?
============================================================ */

-- Insert values into TINYINT column
INSERT INTO subway_sub_exp (quantity)
VALUES (-128), (127);

-- Increment -128 by 1
UPDATE subway_sub_exp
SET quantity = quantity + 1
WHERE sub_id = 1;

SELECT sub_id, quantity
FROM subway_sub_exp
WHERE sub_id = 1;
/* Output:
+--------+---------+
|sub_id  |quantity |
+--------+---------+
|1       |-127     |
+--------+---------+
Explanation: Simply added 1 to -128 resulting in -127. Incrementing -128
is possible until the value reaches the maxium value of 127 for TINYINT. */

-- Increment 127 by 1
UPDATE subway_sub_exp
SET quantity = quantity + 1
WHERE sub_id = 2;

SELECT sub_id, quantity
FROM subway_sub_exp
WHERE sub_id = 2;
/* Output:
Error Code: 1264. Out of range value for column 'quantity' at row 1

Explanation: Can't increment 127 because TINYINT's max value limit is 127. */

-- Reset first value back to -128
UPDATE subway_sub_exp
SET quantity = -128
WHERE sub_id = 1;

-- Decrement -128 by 1
UPDATE subway_sub_exp
SET quantity = quantity - 1
WHERE sub_id = 1;
/* Output:
Error Code: 1264. Out of range value for column 'quantity' at row 1

Explanation: Can't decrement -128 because of TINYINT's minimum value
limit of -128. */

-- Decrement 127 by 1
UPDATE subway_sub_exp
SET quantity = quantity - 1
WHERE sub_id = 2;

SELECT sub_id, quantity
FROM subway_sub_exp
WHERE sub_id = 2;
/* Output:
+--------+---------+
|sub_id  |quantity |
+--------+---------+
|2       |126      |
+--------+---------+
Explanation: Simply subtracted 127 by 1 resulting in 126. Decrementing 127
is possible until the value reaches the minimum value limit of -128 for TINYINT. */ 


/* =============================================================================
								QUESTION 2
What happens if you try to insert/update ENUM values with more than one choice?
With an invalid selection? How is this behavior different with the SET field.
============================================================================== */

-- Insert more than one choice into ENUM value
INSERT INTO subway_sub_exp (bread_quality)
VALUES ('burnt,soggy');
/* Output:
Error Code: 1265. Data truncated for column 'bread_quality' at row 1

Explanation: Only allowed one ENUM value per row/record. */

-- Insert a valid ENUM value
INSERT INTO subway_sub_exp (bread_quality)
VALUES ('burnt');
-- Update ENUM value with more than one choice
UPDATE subway_sub_exp
SET bread_quality = ('toasted,dry')
WHERE sub_id = 3;
/* Output:
Error Code: 1265. Data truncated for column 'bread_quality' at row 1

Explanation: Can't update with more than one choice because only allowed one
choice for the ENUM value in each row/record. */

-- Insert invalid selection
INSERT INTO subway_sub_exp (bread_quality)
VALUES ('moldy');
/* Output:
Error Code: 1265. Data truncated for column 'bread_quality' at row 1

Explanation: Only allowed to insert values/choices that are predefined
when creating the table. */

-- Update with invalid selection
UPDATE subway_sub_exp
SET bread_quality = ('smooshed')
WHERE sub_id = 3;
/* Output:
Error Code: 1265. Data truncated for column 'bread_quality' at row 1

Explanation: Only allowed to update with values/choices that are predefined
when creating the table. */

-- Insert multiple choices into SET field
INSERT INTO subway_sub_exp (experience)
VALUES ('fine,good');

SELECT sub_id, experience
FROM subway_sub_exp
WHERE sub_id = 4;
/* Output:
+--------+-----------+
|sub_id  |experience |
+--------+-----------+
|4       |fine,good  |
+--------+-----------+
Explanation: SET type simply can take on multiple choices per row/record. */

-- Update with multiple choices to SET field
UPDATE subway_sub_exp
SET experience = 'fine,good,bad'
WHERE sub_id = 4;

SELECT sub_id, experience
FROM subway_sub_exp
WHERE sub_id = 4;
/* Output:
+--------+-----------------+
|sub_id  |experience       |
+--------+-----------------+
|4       |fine,good,bad    |
+--------+-----------------+
Explanation: SET type can be updated with multiple choices per row/record. */

-- Inserting and Updating with invalid selections for SET type
INSERT INTO subway_sub_exp (experience)
VALUES ('ok');

UPDATE subway_sub_exp
SET experience = 'okay'
WHERE sub_id = 4;
/* Outputs:
Error Code: 1265. Data truncated for column 'bread_quality' at row 1
Error Code: 1265. Data truncated for column 'bread_quality' at row 1

Explanation: Just can't insert/update with invalid selection, causes error. */


/* =======================================================================================
									QUESTION 3
Create rows with both DATE and TIME fields and with one year < 1000, one time > 100 hours. 
Use the following methods of creating a datetime from a date and time and report the
differences (substitute with your respective column names):
- datetime = CONCAT(date, ' ', time);
- STR_TO_DATE(CONCAT(date, ' ', time), '%Y-%m-%d %H:%i:%s');
- SELECT TIMESTAMP(date,time);
======================================================================================== */
INSERT INTO subway_sub_exp (purchase_date, purchase_time)
VALUES ('2020-05-15', '03:33:33'), -- late night meal
	('2021-02-19', '00:01:01'), -- midnight snack
    ('0999-12-12', '333:33:33'); -- year < 1000 and time > 100 hours

-- Create a datetime from a "normal" date and time
-- Method Used: datetime = CONCAT(date, ' ', time);
UPDATE subway_sub_exp
SET purchase_dt = CONCAT(purchase_date, ' ', purchase_time)
WHERE sub_id = 7; 

SELECT purchase_dt
FROM subway_sub_exp
WHERE sub_id = 7;
/* Output is normal by datetime format standards:
+---------------------+
|purchase_dt          |
+---------------------+
|2020-05-15 03:33:33  |
+---------------------+ */

-- Create a datetime from a "unconventional" date and time
-- Method Used: datetime = CONCAT(date, ' ', time);
UPDATE subway_sub_exp
SET purchase_dt = CONCAT(purchase_date, ' ', purchase_time)
WHERE sub_id = 9; -- row where date = '0999-12-12' and time = '333:33:33'
/* Output:
Error Code: 1292. Incorrect datetime value '0999-12-12 333:33:33' for column
'purchase_dt' at row 1

Explanation: DATETIME only supports a range of '1000-01-01 00:00:00' to
'9999-12-31 23:59:59'. */

-- Create a second datetime from a "normal" date and time
-- Method Used: STR_TO_DATE(CONCAT(date, ' ', time), '%Y-%m-%d %H:%i:%s');
UPDATE subway_sub_exp
SET purchase_dt = STR_TO_DATE(CONCAT(purchase_date, ' ', purchase_time), '%Y-%m-%d %H:%i:%s')
WHERE sub_id = 8;

SELECT purchase_dt
FROM subway_sub_exp
WHERE sub_id = 8;
/* Output is normal by datetime format standards:
+---------------------+
|purchase_dt          |
+---------------------+
|2021-02-19 01:11:11  |
+---------------------+ */

-- Create a second datetime from a "unconventional" date and time
-- Method Used: STR_TO_DATE(CONCAT(date, ' ', time), '%Y-%m-%d %H:%i:%s');
UPDATE subway_sub_exp
SET purchase_dt = STR_TO_DATE(CONCAT(purchase_date, ' ', purchase_time), '%Y-%m-%d %H:%i:%s')
WHERE sub_id = 9; -- row where date = '0999-12-12' and time = '333:33:33'
/* Output:
Error Code: 1411. Incorrect datetime value '0999-12-12 333:33:33' for function
str_to_date

Explanation: DATETIME only supports a range of '1000-01-01 00:00:00' to
'9999-12-31 23:59:59'. */


-- Create timestamp with a valid date and time
-- Method Used: SELECT TIMESTAMP(date,time);
SELECT TIMESTAMP('2050-11-02','22:22:22');
/* Output is normal by timestamp format standards:
+-----------------------------------+
|TIMESTAMP('2050-11-02','22:22:22') |
+-----------------------------------+
|2050-11-02 22:22:22                |
+-----------------------------------+ */

-- Create timestamp with a unsupported date and time
-- Method Used: SELECT TIMESTAMP(date,time);
SELECT TIMESTAMP('0999-12-12', '333:33:33');
/* Output is normal by timestamp format standards:
+-------------------------------------+
|TIMESTAMP('0999-12-12', '333:33:33') |
+-------------------------------------+
|0999-12-25 21:33:33                  |
+-------------------------------------+
Explanation: Even though TIMESTAMP supports a range of '1970-01-01 00:00:01' UTC to
'2038-01-19 03:14:07' UTC, using a SELECT statement returns a result. */

-- Create timestamp with a invalid date and time
-- Method Used: SELECT TIMESTAMP(date,time);
SELECT TIMESTAMP('0000-00-00', '18:19:20');
/* Output is normal by timestamp format standards:
+------------------------------------+
|TIMESTAMP('0000-00-00', '18:19:20') |
+------------------------------------+
|NULL                                |
+------------------------------------+
Explanation: '0000-00-00'is an unacceptable date and considered NULL.*/


/* =======================================================================================
										QUESTION 4
Create a float with at least 5 digits of precision.
Set the DECIMAL to 5* the float val:
       SETdec = fl*5 WHERE key_id=x;
Do the same in reverse.  What are your observations about precision with these data types? 
Did anything unexpected happen?
======================================================================================= */
-- Create a float with at least 5 digits of precision.
UPDATE subway_sub_exp
SET price_float = 123.45678
WHERE sub_id = 1;

SELECT price_float
FROM subway_sub_exp
WHERE sub_id = 1;
/* Output:
+-------------+
|price_float  |
+-------------+
|123.457      |
+-------------+
Explanation: The float value automatically rounded to three decimal places
because precision was not specified when creating this table. */

-- Set the DECIMAL to 5* the float val: SETdec = fl*5 WHERE key_id=x;
UPDATE subway_sub_exp
SET price_decimal = price_float * 5
WHERE sub_id = 1;
/* Output:
1 row(s) affected, 1 warning(s): 1265 Data truncated for column 'price_decimal' at row 1
Rows matched: 1  Changed: 1  Warnings: 1	0.016 sec */
SELECT price_decimal, price_float
FROM subway_sub_exp
WHERE sub_id = 1;
/* Output:
+--------------+------------+
|price_decimal |price_float |
+--------------+------------+
|617.284       |123.457     |
+--------------+------------+
Explanation: The resulting number 617.284 is a little off if considering this
expression: 123.457 * 5 = 617.285 (rounded to 3 decimal places). If original float value
123.45678 is multiplied by 5, the result would be more accurate: 123.45678 * 5 = 617.2839
or 617.284 (rounded to 3 decimal places). Basically, precision affects rounding of values. */

-- Do the same in reverse.
-- Create a decimal value with at least 5 digits of precision.
UPDATE subway_sub_exp
SET price_decimal = 876.54321
WHERE sub_id = 2;
/* Output:
1 row(s) affected, 1 warning(s): 1265 Data truncated for column 'price_decimal' at row 1
Rows matched: 1  Changed: 1  Warnings: 1	0.015 sec */
SELECT price_decimal
FROM subway_sub_exp
WHERE sub_id = 1;
/* Output:
+--------------+
|price_decimal |
+--------------+
|876.543       |
+--------------+
Explanation: Specified when creating table, only allowed 3 decimal places for DECIMAL value. */

-- Set the FLOAT to 5* the decimal val: SET float = dec*5 WHERE key_id=x;
UPDATE subway_sub_exp
SET price_float = price_decimal * 5
WHERE sub_id = 2;

SELECT price_float
FROM subway_sub_exp
WHERE sub_id = 2;
/* Output:
+------------+
|price_float |
+------------+
|4382.71     |
+------------+
Explanation: This float value is not rounded correctly because of the nature of float numbers.
This float value is only allowed 6 digits and since there are 4 digits before the decimal, only
2 decimal places are allowed. The decimal number in the record 876.543 multiplied by 5 should
result in 4382.715 or 4382.72 (rounded to 2 decimal places). If the original specified decimal
value 876.54321 is multiplied with 5, the result would be 4382.71605 or 4382.72 (rounded to 2
decimal places). Again. precision and data types matter because they can affect rounding and
storage of data negatively. */


/* ==========================================================================================
										QUESTION 5
Use each of the operators in the Table of Comparison Operators
1. For "like" use 4 separate patterns.  One with a % at the beginning, one with % at the
   end, one with % at the beginning and end of a search term, and one with a % in the middle.
2. For BETWEEN and NOT BETWEEN, generate the same results using > & < in the WHERE clause.
3. For COALESCE, generate the same results using other operators in the WHERE clause.
========================================================================================== */
-- This is how my subway_sub_exp table looks like at this point
SELECT * FROM subway_sub_exp;
/* table: subway_sub_exp
+-------+---------+------+-----+--------------+------------+--------------+--------------+--------------+--------------+--------------------+
|sub_id |quantity |bread |meat |price_decimal |price_float |bread_quality |experience    |purchase_date |purchase_time |purchase_dt         |
+-------+---------+------+-----+--------------+------------+--------------+--------------+--------------+--------------+--------------------+
|1      |-128     |NULL  |NULL |617.284       |123.457     |NULL          |NULL          |NULL          |NULL          |NULL                |
+-------+---------+------+-----+--------------+------------+--------------+--------------+--------------+--------------+--------------------+
|2      |126      |NULL  |NULL |876.543       |4382.71     |NULL          |NULL          |NULL          |NULL          |NULL                |
+-------+---------+------+-----+--------------+------------+--------------+--------------+--------------+--------------+--------------------+
|3      |NULL     |NULL  |NULL |NULL          |NULL        |burnt         |NULL          |NULL          |NULL          |NULL                |
+-------+---------+------+-----+--------------+------------+--------------+--------------+--------------+--------------+--------------------+
|4      |NULL     |NULL  |NULL |NULL          |NULL        |NULL          |fine,good,bad |NULL          |NULL          |NULL                |
+-------+---------+------+-----+--------------+------------+--------------+--------------+--------------+--------------+--------------------+
|7      |NULL     |NULL  |NULL |NULL          |NULL        |NULL          |NULL          |2020-05-15    |03:33:33      |2020-05-15 03:33:33 |
+-------+---------+------+-----+--------------+------------+--------------+--------------+--------------+--------------+--------------------+
|8      |NULL     |NULL  |NULL |NULL          |NULL        |NULL          |NULL          |2021-02-19    |01:11:11      |2021-02-19 01:11:11 |
+-------+---------+------+-----+--------------+------------+--------------+--------------+--------------+--------------+--------------------+
|9      |NULL     |NULL  |NULL |NULL          |NULL        |NULL          |NULL          |0999-12-12    |333:33:33     |NULL                |
+-------+---------+------+-----+--------------+------------+--------------+--------------+--------------+--------------+--------------------+
This table will need to be filled with data on the customer subway sub experience

Below are the queries for filling in the table for only six records/rows. */

-- Delete all current rows/records
DELETE FROM subway_sub_exp
WHERE sub_id BETWEEN 0 AND 9;

-- Insert data for six rows/records
INSERT INTO subway_sub_exp (quantity, bread, meat, price_decimal, bread_quality, experience, purchase_date)
VALUES
	(3, 'Flatbread', 'Buffalo Chicken', 13.870, 'soggy', 'fine', '2020-12-25'),
    (30, 'Italian Herbs & Cheese', 'Tuna',  295.530, 'normal', 'good', '2021-02-07'),
    (11, '9-Grain Wheat', 'Meatball',  101.640, 'toasted', 'good', '2021-01-23'),
    (2, 'Italian', 'Bacon Tatum',  28.100, 'underbaked', 'bad', '2021-02-11'),
	(1, 'Italian', 'DrayPotle Steak',  13.980, 'dry', 'bad,dreadful', '2021-02-03'),
    (1, 'Italian', 'Bacon Tatum',  14.050, 'burnt', 'fine', '2021-02-06');

-- Update sub_id to indicate 1 to 6. (Took a couple tries so sub_id values kept increasing)
UPDATE subway_sub_exp
SET sub_id = 1
WHERE sub_id = 23;

UPDATE subway_sub_exp
SET sub_id = 2
WHERE sub_id = 24;

UPDATE subway_sub_exp
SET sub_id = 3
WHERE sub_id = 25;

UPDATE subway_sub_exp
SET sub_id = 4
WHERE sub_id = 26;

UPDATE subway_sub_exp
SET sub_id = 5
WHERE sub_id = 27;

UPDATE subway_sub_exp
SET sub_id = 6
WHERE sub_id = 28;

SELECT
	sub_id,
	quantity,
    bread,
    meat,
    price_decimal,
    bread_quality,
    experience,
    purchase_date
FROM subway_sub_exp;
/* Here is the table with the new data
+-------+---------+-----------------------+----------------+--------------+--------------+-------------+--------------+
|sub_id |quantity |bread                  |meat            |price_decimal |bread_quality |experience   |purchase_date |
+-------+---------+-----------------------+----------------+--------------+--------------+-------------+--------------+
|1      |3        |Flatbread              |Buffalo Chicken |13.870        |soggy         |fine         |2020-12-25    |
+-------+---------+-----------------------+----------------+--------------+--------------+-------------+--------------+
|2      |30       |Italian Herbs & Cheese |Tuna            |295.530       |normal        |good         |2021-02-07    |
+-------+---------+-----------------------+----------------+--------------+--------------+-------------+--------------+
|3      |11       |9-Grain Wheat          |Meatball        |101.640       |toasted       |good         |2021-01-23    |
+-------+---------+-----------------------+----------------+--------------+--------------+-------------+--------------+
|4      |2        |Italian                |Bacon Tatum     |28.100        |underbaked    |bad          |2021-02-11    |
+-------+---------+-----------------------+----------------+--------------+--------------+-------------+--------------+
|5      |1        |Italian                |DrayPotle Steak |13.980        |dry           |bad,dreadful |2021-02-03    |
+-------+---------+-----------------------+----------------+--------------+--------------+-------------+--------------+
|6      |1        |Italian                |Bacon Tatum     |14.050        |burnt         |fine         |2021-02-06    |
+-------+---------+-----------------------+----------------+--------------+--------------+-------------+--------------+ */

-- Finally, time to make use of all comparison operators

-- Find the greatest and least quantity of subs purchased
-- Use GREATEST() and LEAST() comparison operators:
SELECT
	GREATEST(3, 30, 11, 2, 1, 1), -- Result: 30 (someone was fond of tuna on italian herb & cheese bread)
	LEAST(3, 30, 11, 2, 1, 1); -- Result: 1 (DrayPotle Steak and Bacon Tatum subs were the least purchased)

-- Find the records of the customers who purchased either DrayPotle Steak or Bacon Tatum subs
-- Use IN() comparison:
SELECT
	sub_id,
	quantity,
    bread,
    meat,
    price_decimal,
    bread_quality,
    experience,
    purchase_date
FROM subway_sub_exp
WHERE meat IN ('DrayPotle Steak', 'Bacon Tatum');
/* Output:
+-------+---------+-----------------------+----------------+--------------+--------------+-------------+--------------+
|sub_id |quantity |bread                  |meat            |price_decimal |bread_quality |experience   |purchase_date |
+-------+---------+-----------------------+----------------+--------------+--------------+-------------+--------------+
|4      |2        |Italian                |Bacon Tatum     |28.100        |underbaked    |bad          |2021-02-11    |
+-------+---------+-----------------------+----------------+--------------+--------------+-------------+--------------+
|5      |1        |Italian                |DrayPotle Steak |13.980        |dry           |bad,dreadful |2021-02-03    |
+-------+---------+-----------------------+----------------+--------------+--------------+-------------+--------------+
|6      |1        |Italian                |Bacon Tatum     |14.050        |burnt         |fine         |2021-02-06    |
+-------+---------+-----------------------+----------------+--------------+--------------+-------------+--------------+ */

-- Now take a look at the customers who did not purchase DrayPotle Steak or Bacon Tatum subs
-- Use NOT IN() comparison operator:
SELECT
	sub_id,
	quantity,
    bread,
    meat,
    price_decimal,
    bread_quality,
    experience,
    purchase_date
FROM subway_sub_exp
WHERE meat NOT IN ('DrayPotle Steak', 'Bacon Tatum');
/* Output:
+-------+---------+-----------------------+----------------+--------------+--------------+-------------+--------------+
|sub_id |quantity |bread                  |meat            |price_decimal |bread_quality |experience   |purchase_date |
+-------+---------+-----------------------+----------------+--------------+--------------+-------------+--------------+
|1      |3        |Flatbread              |Buffalo Chicken |13.870        |soggy         |fine         |2020-12-25    |
+-------+---------+-----------------------+----------------+--------------+--------------+-------------+--------------+
|2      |30       |Italian Herbs & Cheese |Tuna            |295.530       |normal        |good         |2021-02-07    |
+-------+---------+-----------------------+----------------+--------------+--------------+-------------+--------------+
|3      |11       |9-Grain Wheat          |Meatball        |101.640       |toasted       |good         |2021-01-23    |
+-------+---------+-----------------------+----------------+--------------+--------------+-------------+--------------+ */

-- Let's see how many subs were purchased in Feburary 2021 up to the day of the Super Bowl
-- Use >= and <= comparison operators:
SELECT
	quantity,
    meat,
    purchase_date    
FROM subway_sub_exp
WHERE purchase_date >= '2021-02-01' AND purchase_date <= '2021-02-07'
ORDER BY purchase_date;
/* Output
+---------+----------------+--------------+
|quantity |meat            |purchase_date |
+---------+----------------+--------------+
|1        |DrayPotle Steak |2021-02-03    |
+---------+----------------+--------------+
|1        |Bacon Tatum     |2021-02-06    |
+---------+----------------+--------------+
|30       |Tuna            |2021-02-07    | <-- Super Bowl day
+---------+----------------+--------------+ */

-- Find which sub(s) gave the most pleasant experience(s) to the customer
-- USE = comparison operator:
SELECT
	sub_id,
	meat,
    experience
FROM subway_sub_exp
WHERE experience = 'good';
/* Output
+-------+---------+--------------+
|sub_id |meat     |experience    |
+-------+---------+--------------+
|2      |Tuna     |good          |
+-------+---------+--------------+
|3      |Meatball |good          |
+-------+---------+--------------+ */

-- What about those who did not have a good experience?
-- Use <> comparison operator:
SELECT
	sub_id,
	meat,
    experience
FROM subway_sub_exp
WHERE experience <> 'good';
/* Output
+-------+----------------+-------------+
|sub_id |meat            |experience   |
+-------+----------------+-------------+
|1      |Buffalo Chicken |fine         |
+-------+----------------+-------------+
|4      |Bacon Tatum     |bad          |
+-------+----------------+-------------+
|5      |DrayPotle Steak |bad,dreadful |
+-------+----------------+-------------+
|6      |Bacon Tatum     |fine         |
+-------+----------------+-------------+ */

-- Looks like there were some fine experiences, let's weed those out to just see the worst ones
-- Use != comparison operator:
SELECT
	sub_id,
	meat,
    experience
FROM subway_sub_exp
WHERE experience != 'good' AND experience != 'fine';
/* Output:
+-------+----------------+-------------+
|sub_id |meat            |experience   |
+-------+----------------+-------------+
|4      |Bacon Tatum     |bad          |
+-------+----------------+-------------+
|5      |DrayPotle Steak |bad,dreadful |
+-------+----------------+-------------+ */

-- Let's observe the variety of breads in the table
-- Use LIKE with 4 separate patterns:

SELECT bread
FROM subway_sub_exp
WHERE bread LIKE '%n';
/* Output:
+--------+
|bread   |
+--------+
|Italian |
+--------+
|Italian |
+--------+
|Italian |
+--------+ */

SELECT bread
FROM subway_sub_exp
WHERE bread LIKE 'i%';
/* Output:
+-----------------------+
|bread                  |
+-----------------------+
|Italian Herbs & Cheese |
+-----------------------+
|Italian                |
+-----------------------+
|Italian                |
+-----------------------+
|Italian                |
+-----------------------+ */

SELECT bread
FROM subway_sub_exp
WHERE bread LIKE '%ea%';
/* Output:
+--------------+
|bread         |
+--------------+
|Flatbread     |
+--------------+
|9-Grain Wheat |
+--------------+ */

SELECT bread
FROM subway_sub_exp
WHERE bread LIKE 'i%e';
/* Output:
+-----------------------+
|bread                  |
+-----------------------+
|Italian Herbs & Cheese |
+-----------------------+ */

-- Use NOT LIKE:
SELECT bread
FROM subway_sub_exp
WHERE bread NOT LIKE 'i%e';
/* Output:
+--------------+
|bread         |
+--------------+
|Flatbread     |
+--------------+
|9-Grain Wheat |
+--------------+
|Italian       |
+--------------+
|Italian       |
+--------------+
|Italian       |
+--------------+ */

-- Enough with observing subway bread types. Let's see which subs cost about 13 to 14 dollars
-- Use BETWEEN:
SELECT
	bread,
    meat,
    price_decimal / quantity AS price_per_sub
FROM subway_sub_exp
WHERE price_decimal / quantity BETWEEN 12.99 AND 15;
/* Output:
+--------+----------------+--------------+
|bread   |meat            |price_per_sub |
+--------+----------------+--------------+
|Italian |Bacon Tatum     |14.0500000    |
+--------+----------------+--------------+
|Italian |DrayPotle Steak |13.9800000    |
+--------+----------------+--------------+
|Italian |Bacon Tatum     |14.0500000    |
+--------+----------------+--------------+ */

-- Use > & < to generate same results as above:
SELECT
	bread,
    meat,
    price_decimal / quantity AS price_per_sub
FROM subway_sub_exp
WHERE price_decimal / quantity > 12.99 AND price_decimal / quantity < 15;
/* Output:
+--------+----------------+--------------+
|bread   |meat            |price_per_sub |
+--------+----------------+--------------+
|Italian |Bacon Tatum     |14.0500000    |
+--------+----------------+--------------+
|Italian |DrayPotle Steak |13.9800000    |
+--------+----------------+--------------+
|Italian |Bacon Tatum     |14.0500000    |
+--------+----------------+--------------+ */

-- Are there any subs that cost less than $10?!!
-- Use NOT BETWEEN:
SELECT
	bread,
    meat,
    price_decimal / quantity AS price_per_sub
FROM subway_sub_exp
WHERE price_decimal / quantity NOT BETWEEN 10.01 AND 10000;
/* Output:
+-----------------------+----------------+--------------+
|bread                  |meat            |price_per_sub |
+-----------------------+----------------+--------------+
|Flatbread              |Buffalo Chicken |4.6233333     |  <-- Wow!
+-----------------------+----------------+--------------+
|Italian Herbs & Cheese |Tuna            |9.8510000     |
+-----------------------+----------------+--------------+
|9-Grain Wheat          |Meatball        |9.2400000     |
+-----------------------+----------------+--------------+ */

-- Use > & < to generate same results as above:
SELECT
	bread,
    meat,
    price_decimal / quantity AS price_per_sub
FROM subway_sub_exp
WHERE price_decimal / quantity < 10.01 AND price_decimal / quantity > 0;
/* Output:
+-----------------------+----------------+--------------+
|bread                  |meat            |price_per_sub |
+-----------------------+----------------+--------------+
|Flatbread              |Buffalo Chicken |4.6233333     |  <-- Wow!
+-----------------------+----------------+--------------+
|Italian Herbs & Cheese |Tuna            |9.8510000     |
+-----------------------+----------------+--------------+
|9-Grain Wheat          |Meatball        |9.2400000     |
+-----------------------+----------------+--------------+ */

-- Use COALESCE on bread_quality and NULL values:
SELECT COALESCE(NULL, NULL, 'soggy', NULL, 'burnt', 'dry', NULL, 'toasted', 'underbaked', 'normal', NULL) AS bread_quality;
/* Output:
+--------------+
|bread_quality |
+--------------+
|soggy         |
+--------------+ */

-- Use IS NOT NULL in the WHERE clause to generate the same results as above:
SELECT bread_quality
FROM subway_sub_exp
WHERE bread_quality IS NOT NULL
LIMIT 1;
/* Output:
+--------------+
|bread_quality |
+--------------+
|soggy         |
+--------------+ */

-- Use <=> in the WHERE clause to generate the same results as above:
SELECT bread_quality
FROM subway_sub_exp
WHERE bread_quality <=> 'soggy'
LIMIT 1;
/* Output:
+--------------+
|bread_quality |
+--------------+
|soggy         |
+--------------+ */

-- Let's look at the purchase_dt column that wasa purposely not filled with data
-- Use IS NULL:
SELECT sub_id, purchase_dt
FROM subway_sub_exp
WHERE purchase_dt IS NULL;
/* Output:
+-------+------------+
|sub_id |purchase_dt |
+-------+------------+
|1      |NULL        |
+-------+------------+
|2      |NULL        |
+-------+------------+
|3      |NULL        |
+-------+------------+
|4      |NULL        |
+-------+------------+
|5      |NULL        |
+-------+------------+
|6      |NULL        |
+-------+------------+ */

-- Compare a bad experience with an even worse experience
-- Use STRCMP():
SELECT STRCMP('bad', 'bad,dreadful');
/* Output:
+------------------------------+
|STRCMP('bad', 'bad,dreadful') |
+------------------------------+
|-1                            |
+------------------------------+
Explanation: 'bad' < 'bad,dreadful', returns -1. */

-- Use ISNULL() for a NULL value in purchase_time column:
SELECT ISNULL(purchase_time)
FROM subway_sub_exp
WHERE sub_id = 1;
/* Output:
+----------------------+
|ISNULL(purchase_time) |
+----------------------+
|1                     |
+----------------------+
Explanation: Because the value is NULL, this function returns 1.*/

-- What day was Super Bowl 2021?
-- Use INTERVAL():
SELECT INTERVAL(
	'2020-12-25',
	'2021-02-07',
	'2021-01-23',
	'2021-02-11',
	'2021-02-03',
	'2021-02-06');
/* Output
+--------------+
|INTERVAL(     |
|'2020-12-25', |
|'2021-02-07', |
|'2021-01-23', |
|'2021-02-11', |
|'2021-02-03', |
|'2021-02-06'  |
+--------------+
|0             |
+--------------+ 
Explanation: Returned 0 because the date listed after the first date is the first date
that is greater than the first date in the list. Super Bowl day was '2021-02-07'. */