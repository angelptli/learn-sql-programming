-- Working with Triggers

DROP TABLE IF EXISTS sellers;
DROP TABLE IF EXISTS tuna_sales;
DROP TABLE IF EXISTS seller_earnings;

-- These tables keep track of tuna fish sales at the seasonal fish auction

-- Table of tuna fish sellers
CREATE TABLE sellers (
    seller_id MEDIUMINT UNSIGNED NOT NULL AUTO_INCREMENT,
    tuna_quantity TINYINT UNSIGNED NOT NULL,
    tuna_sold TINYINT UNSIGNED NOT NULL DEFAULT 0,
    total_earnings DECIMAL(15,2) NOT NULL DEFAULT 0,
    PRIMARY KEY (seller_id)
);

-- Table of tuna fish sold
CREATE TABLE tuna_sales (
    tuna_id SMALLINT UNSIGNED NOT NULL AUTO_INCREMENT,
    seller_id MEDIUMINT UNSIGNED NOT NULL,
    price DECIMAL(15,2) NOT NULL,
    PRIMARY KEY (tuna_id)
);

-- Table of earnings for each tuna fish sold
CREATE TABLE seller_earnings (
    tuna_id SMALLINT UNSIGNED NOT NULL,
    seller_id MEDIUMINT UNSIGNED NOT NULL,
    earnings DECIMAL(15,2) NOT NULL, -- subject to 5% commission fee
    PRIMARY KEY (tuna_id)
);

-- Table Structure: sellers
DESCRIBE sellers;
/*
+----------------+---------------------+------+-----+---------+-----------------+
| Field          | Type                | NULL | Key | Default | Extra           |
+----------------+---------------------+------+-----+---------+-----------------+
| seller_id	     | mediumint unsigned  | NO   | PRI | NULL    | auto_increment  |
+----------------+---------------------+------+-----+---------+-----------------+
| tuna_quantity  | tinyint unsigned    | NO   |     | NULL    |                 |
+----------------+---------------------+------+-----+---------+-----------------+
| tuna_sold      | tinyint unsigned    | NO   |     | 0       |                 | 
+----------------+---------------------+------+-----+---------+-----------------+
| total_earnings | decimal(15,2)       | NO   |     | 0       |                 |
+----------------+---------------------+------+-----+---------+-----------------+ */

-- Table Structure: tuna_sales
DESCRIBE tuna_sales;
/*
+---------------+---------------------+------+-----+---------+-----------------+
| Field         | Type                | NULL | Key | Default | Extra           |
+---------------+---------------------+------+-----+---------+-----------------+
| tuna_id       | smallint unsigned   | NO   | PRI | NULL    | auto_increment  |
+---------------+---------------------+------+-----+---------+-----------------+
| seller_id     | mediumint unsigned  | NO   |     | NULL    |                 |
+---------------+---------------------+------+-----+---------+-----------------+
| price         | decimal(15,2)       | NO   |     | NULL    |                 | 
+---------------+---------------------+------+-----+---------+-----------------+ */

-- Table Structure: seller_earnings
DESCRIBE seller_earnings;
/*
+----------------+---------------------+------+-----+---------+-----------------+
| Field          | Type                | NULL | Key | Default | Extra           |
+----------------+---------------------+------+-----+---------+-----------------+
| seller_id	     | mediumint unsigned  | NO   |     | NULL    |                 |
+----------------+---------------------+------+-----+---------+-----------------+
| tuna_id        | smallint unsigned   | NO   |     | NULL    |                 |
+----------------+---------------------+------+-----+---------+-----------------+
| earnings       | decimal(15,2)       | NO   |     | NULL    |                 | 
+----------------+---------------------+------+-----+---------+-----------------+ */

-- Add some sellers into the sellers table
INSERT INTO sellers (tuna_quantity)
VALUES (20), (15), (10);
-- There are now three sellers at the seasonal fish auction, each with a quantity of tuna fish up for auction
SELECT * FROM sellers;
/* Starting table view: sellers
+-----------+---------------+-----------+----------------+
| seller_id | tuna_quantity | tuna_sold | total_earnings |
+-----------+---------------+-----------+----------------+
| 1         | 20            | 0         | 0.00           |
+-----------+---------------+-----------+----------------+
| 2         | 15            | 0         | 0.00           |
+-----------+---------------+-----------+----------------+
| 3         | 10            | 0         | 0.00           |
+-----------+---------------+-----------+----------------+ */

/* Create a BEFORE INSERT trigger:
A rule of the seasonal fish auction is that sellers can put their fish on auction so long as they pay
a 5% commission fee for each of the fish sold. So whenever a tuna fish is sold, the fish price is
recorded in the tuna_sales table and the price minus the commission fee is recorded as earnings in
the seller_earnings table. A simple way to take off 5% from the price is to multiply it with 0.95 (1 - 0.05). */
DELIMITER $$
CREATE TRIGGER calc_earnings
    BEFORE INSERT ON tuna_sales FOR EACH ROW
BEGIN
    INSERT INTO seller_earnings (seller_id, tuna_id, earnings)
    VALUES (NEW.seller_id, NEW.tuna_id, NEW.price * 0.95);
END$$
DELIMITER ;

/* Create a AFTER INSERT trigger:
We also want to update the sellers table to update the seller's quantity of tuna fish left, the number
of tuna fish sold, and their total earnings after inserting into the tuna_sales table. */
DELIMITER $$
CREATE TRIGGER update_sellers
    AFTER INSERT ON seller_earnings FOR EACH ROW
BEGIN
    UPDATE sellers
    SET sellers.tuna_quantity = sellers.tuna_quantity - 1,
        sellers.tuna_sold = sellers.tuna_sold + 1,
        sellers.total_earnings = sellers.total_earnings + NEW.earnings
    WHERE sellers.seller_id = NEW.seller_id;   
END$$
DELIMITER ;

/* Create a BEFORE UPDATE trigger:
If the price of a tuna fish sold must be updated with a changed or corrected price, before updating
the price we need to calculate the new earnings by multiplying the the correct price with the commission
fee (5%) and update the seller_earnings table with the new correct earnings value. */
DELIMITER $$
CREATE TRIGGER before_update_price
    BEFORE UPDATE ON tuna_sales FOR EACH ROW
BEGIN
    UPDATE seller_earnings
    SET seller_earnings.earnings = NEW.price * 0.95
    WHERE seller_earnings.tuna_id = NEW.tuna_id;
END$$
DELIMITER ;

/* Create a AFTER UPDATE trigger:
We also want to update the sellers table to correct the total_earnings amount whenever we update the
tuna_sales and seller_earnings table with the corrected data. We can calculate the correct total_earnings
by subtracting the old earnings amount then adding the new correct earnings amount to the total_earnings
amount. */
DELIMITER $$
CREATE TRIGGER after_update_seller_earnings
    AFTER UPDATE ON seller_earnings FOR EACH ROW
BEGIN
    UPDATE sellers
    SET sellers.total_earnings = sellers.total_earnings - OLD.earnings + NEW.earnings
    WHERE sellers.seller_id = NEW.seller_id;
END$$    
DELIMITER ;

/* Create a BEFORE DELETE trigger:
If a tuna fish sale was mistakenly recorded for a tuna fish that was not indeed sold, we will delete
the record in the tuna_sales table as well as the seller_earnings table. */
DELIMITER $$
CREATE TRIGGER before_delete_tuna_sale
    BEFORE DELETE ON tuna_sales FOR EACH ROW
BEGIN
    DELETE FROM seller_earnings
    WHERE OLD.tuna_id = tuna_id;
END$$
DELIMITER ;

/* Create a AFTER DELETE trigger:
We need to also update the sellers table with the correct data after deleting a record of a incorrect sale
of tuna fish from the tuna_sales and seller_earnings tables. We need to use the old data from the
seller_earnings table to subtract from sellers table data. */
DELIMITER $$
CREATE TRIGGER after_delete_seller_earnings
    AFTER DELETE ON seller_earnings FOR EACH ROW
BEGIN
    UPDATE sellers
    SET sellers.tuna_quantity = sellers.tuna_quantity + 1,
        sellers.tuna_sold = sellers.tuna_sold - 1,
        sellers.total_earnings = sellers.total_earnings - OLD.earnings
    WHERE sellers.seller_id = OLD.seller_id;
END$$
DELIMITER ;

/* After creating the six triggers above, we can now insert, update, and delete data and check that all
the triggers work. Below are the statements used to test out the triggers. */

-- Insert two sales of tuna fish from seller 1 both priced at $60,000
INSERT INTO tuna_sales (tuna_id, seller_id, price)
VALUES (1, 1, 60000);
INSERT INTO tuna_sales (tuna_id, seller_id, price)
VALUES (2, 1, 60000);
-- Let's see each table's data after these inserts
SELECT * FROM tuna_sales;
/* 
+---------+-----------+----------+
| tuna_id | seller_id | price    |
+---------+-----------+----------+
| 1       | 1         | 60000.00 |
+---------+-----------+----------+
| 2       | 1         | 60000.00 |
+---------+-----------+----------+ */

SELECT * FROM seller_earnings;
/* 
+---------+-----------+-------------+
| tuna_id | seller_id | earnings    |
+---------+-----------+-------------+
| 1       | 1         | 57000.00    | <- (60000.00 * 0.95)
+---------+-----------+-------------+
| 2       | 1         | 57000.00    | <- (60000.00 * 0.95)
+---------+-----------+-------------+
Explanation: The BEFORE INSERT trigger named calc_earnings triggers an insert into the seller_earnings table
for each row inserted in the tuna_sales table. The calc_earnings trigger also calculates the earnings amount
in the seller_earnings table by multiplying the price from the tuna_sales with 0.95, in other words, with the
5% commission fee taken off from the earnings. */

SELECT * FROM sellers;
/*
+-----------+---------------+-----------+----------------+
| seller_id | tuna_quantity | tuna_sold | total_earnings |
+-----------+---------------+-----------+----------------+
| 1         | 18            | 2         | 114000.00      | <- (57000.00 + 57000.00)
+-----------+---------------+-----------+----------------+
| 2         | 15            | 0         | 0.00           |
+-----------+---------------+-----------+----------------+
| 3         | 10            | 0         | 0.00           |
+-----------+---------------+-----------+----------------+
Explanation: The AFTER INSERT trigger named update_sellers triggers whenever a row is inserted into the
seller_earnings table and this causes an update to the sellers table to update the tuna_quantity,
tuna_sold, and total_earnings data. Each row in the seller_earnings table represents the earnings from
one tuna fish sold so in this update, the tuna_quantity is substracted by one for each row inserted
in the seller_earnings table. Likewise, for each row inserted in the seller_earnings table, tuna_sold
gets added by one. The total_earnings is updated by adding to it the earnings amount. */

-- Update the price of the first tuna sale to $55,000
UPDATE tuna_sales
SET price = 55000
WHERE tuna_id = 1;
-- Let's see each table's data after this update
SELECT * FROM tuna_sales;
/* 
+---------+-----------+----------+
| tuna_id | seller_id | price    |
+---------+-----------+----------+
| 1       | 1         | 55000.00 |
+---------+-----------+----------+
| 2       | 1         | 60000.00 |
+---------+-----------+----------+ */

SELECT * FROM seller_earnings;
/* 
+---------+-----------+-------------+
| tuna_id | seller_id | earnings    |
+---------+-----------+-------------+
| 1       | 1         | 52250.00    | <- (55000.00 * 0.95)
+---------+-----------+-------------+
| 2       | 1         | 57000.00    |
+---------+-----------+-------------+
Explanation: The BEFORE UPDATE trigger named before_update_price triggers whenever a price is updated in
the tuna_sales table and this causes an update on the seller_earnings table with an updated earnings
amount, which is calculated by multiplying the new price with 0.95. */

SELECT * FROM sellers;
/*
+-----------+---------------+-----------+----------------+
| seller_id | tuna_quantity | tuna_sold | total_earnings |
+-----------+---------------+-----------+----------------+
| 1         | 18            | 2         | 109250.00      | <- (114000.00 - 57000.00 + 52250.00)
+-----------+---------------+-----------+----------------+
| 2         | 15            | 0         | 0.00           |
+-----------+---------------+-----------+----------------+
| 3         | 10            | 0         | 0.00           |
+-----------+---------------+-----------+----------------+
Explanation: The AFTER UPDATE trigger named after_update_seller_earnings triggers from the updates on the
seller_earnings table and this causes an update on the sellers table. The total_earnings is updated and
calculated by subtracting the old earnings amount from the total_earnings and then adding the new earnings
amount to it to represent the correct total_earnings amount. */

-- Delete the second sale of tuna
DELETE FROM tuna_sales
WHERE tuna_id = 2;
-- Let's see each table's data after this delete
SELECT * FROM tuna_sales;
/* 
+---------+-----------+----------+
| tuna_id | seller_id | price    |
+---------+-----------+----------+
| 1       | 1         | 55000.00 |
+---------+-----------+----------+ */

SELECT * FROM seller_earnings;
/* 
+---------+-----------+-------------+
| tuna_id | seller_id | earnings    |
+---------+-----------+-------------+
| 1       | 1         | 52250.00    |
+---------+-----------+-------------+
Explanation: The BEFORE DELETE trigger named before_delete_tuna_sale triggers whenever a row is deleted
from the tuna_sales table and this causes a delete on the corresponding row(s) in the seller_earnings table. */

SELECT * FROM sellers;
/*
+-----------+---------------+-----------+----------------+
| seller_id | tuna_quantity | tuna_sold | total_earnings |
+-----------+---------------+-----------+----------------+
| 1         | 19            | 1         | 52250.00       | <- (109250.00 - 57000.00)
+-----------+---------------+-----------+----------------+
| 2         | 15            | 0         | 0.00           |
+-----------+---------------+-----------+----------------+
| 3         | 10            | 0         | 0.00           |
+-----------+---------------+-----------+----------------+
Explanation: The AFTER DELETE trigger named after_delete_seller_earnings triggers from the deletion of a
row in the seller_earnings table. The after_delete_seller_earnings trigger makes an update on the sellers
table to subtract the earnings deleted amount with the total_earnings. */
