-- Understanding Design Structures & Performance

CREATE DATABASE online_store;
USE online_store;
/* ////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////
  NOTES: PKs and FKs are added after the tables are filled with dummy data. All average times
  for queries, comparisons, and explanation of results can be found at the very bottom.
 ////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////*/

-- FIRST DESIGN with fewest number of tables, suffixed with _less:

-- Table 1: Create users table for first design. After, use filldb to fill with dummy data.
CREATE TABLE users_less (
    user_email VARCHAR(255) NOT NULL,
    user_pswd VARCHAR(255) NOT NULL, 
    user_first_name VARCHAR(50) NOT NULL,
    user_nickname VARCHAR(50) NULL,
    user_address VARCHAR(255) NOT NULL,
    user_billing_address VARCHAR(255) NOT NULL
);

-- Add user_id PK to users_less table
ALTER TABLE users_less ADD user_id MEDIUMINT UNSIGNED NOT NULL PRIMARY KEY AUTO_INCREMENT FIRST;

-- Table 2: Create orders table for first design. After, use filldb to fill with dummy data.
CREATE TABLE orders_less (
    order_quantity SMALLINT UNSIGNED NOT NULL
);

-- Add order_no PK and empty user_id column to orders_less table
ALTER TABLE orders_less ADD order_no MEDIUMINT UNSIGNED NOT NULL PRIMARY KEY AUTO_INCREMENT FIRST;
ALTER TABLE orders_less ADD user_id MEDIUMINT UNSIGNED NOT NULL AFTER order_no;

-- Update orders_less.user_id = users_less.user_id
UPDATE orders_less
JOIN users_less ON orders_less.order_no = users_less.user_id
SET orders_less.user_id = users_less.user_id
WHERE orders_less.order_no > 0;

-- Make orders_less.user_id into FK
ALTER TABLE orders_less
ADD CONSTRAINT ol_fk_user_id FOREIGN KEY (user_id) REFERENCES users_less (user_id);

-- TEST QUERIES for FIRST DESIGN:

/* 1. Summarize orders by address
           Duration / Fetch
      -------------------------- 
Run 1:   26.204 sec / 3.235 sec
Run 2:   25.359 sec / 3.000 sec
Run 3:   27.391 sec / 2.000 sec
Run 4:   25.703 sec / 2.016 sec
Run 5:   25.938 sec / 2.297 sec
AVG:     26.119 sec / 2.5096 sec */
SELECT
    user_billing_address AS billing_address,
    user_address AS residential_address,
    order_no,
    order_quantity
FROM users_less ul
    JOIN orders_less ol ON ul.user_id = ol.user_id
ORDER BY ul.user_billing_address;

/* 2. Summarize orders by user
         Duration / Fetch
      -------------------------- 
Run 1:  8.000 sec / 0.563 sec
Run 2:  8.047 sec / 0.625 sec
Run 3:  8.047 sec / 0.516 sec
Run 4:  8.406 sec / 0.547 sec
Run 5:  8.484 sec / 0.578 sec
AVG:   8.1968 sec / 0.5658 sec */
SELECT
    ul.user_id,
    ul.user_first_name,
    ol.order_no,
    ol.order_quantity
FROM users_less ul
    JOIN orders_less ol ON ul.user_id = ol.user_id
ORDER BY ul.user_id;

-- Remove some nicknames for the third summary query
UPDATE users_less
SET user_nickname = NULL
WHERE (user_id > 56 AND user_id < 235)
    OR (user_id > 3515 AND user_id < 51681)
    OR (user_id > 81841 AND user_id < 84846)
    OR (user_id > 516518 AND user_id < 651818)
    OR (user_id > 950000 AND user_id < 950515);

/* 3. Count how many users have nicknames
         Duration / Fetch
      -------------------------- 
Run 1:  7.266 sec / 0.000 sec
Run 2:  7.594 sec / 0.000 sec
Run 3:  7.250 sec / 0.000 sec
Run 4:  7.515 sec / 0.000 sec
Run 5:  7.171 sec / 0.000 sec
AVG:   7.3592 sec / 0.000 sec */
SELECT COUNT(user_nickname)
FROM users_less
WHERE user_nickname IS NOT NULL; -- 812,840 with nicknames

-- Encrypt passwords from users_less table
UPDATE users_less
SET user_pswd = CONCAT('*', UPPER(SHA1(UNHEX(SHA1(user_pswd)))))
WHERE user_id > 0;

/* 4. Log in a user with a valid password (producing the necessary columns an app would need
from this query)
         Duration / Fetch
      -------------------------- 
Run 1:  5.438 sec / 0.000 sec
Run 2:  5.344 sec / 0.000 sec
Run 3:  5.359 sec / 0.000 sec
Run 4:  5.359 sec / 0.000 sec
Run 5:  5.375 sec / 0.000 sec
AVG:    5.375 sec / 0.000 sec */
SELECT
    user_id,
    user_email,
    user_pswd AS user_pswd,
    user_first_name,
    user_nickname
FROM users_less
WHERE user_pswd = CONCAT('*', UPPER(SHA1(UNHEX(SHA1('willms.ramon')))));

/* ////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////
  NOTES: PKs and FKs are added after the tables are filled with dummy data. All average times
  for queries, comparisons, and explanation of results can be found at the very bottom.
///////////////////////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////////////////// */
-- SECOND DESIGN with the most efficient set of tables: no prefix and suffix

-- Table 1: Create users table for seconds design. After, use filldb to fill with dummy data.
CREATE TABLE users (
    user_first_name VARCHAR(50) NOT NULL,
    user_nickname VARCHAR(50) NULL
);

-- Add user_id PK to users table
ALTER TABLE users ADD user_id MEDIUMINT UNSIGNED NOT NULL PRIMARY KEY AUTO_INCREMENT FIRST;

-- Table 2: Create credentials table for second design. After, use filldb to fill with dummy data.
CREATE TABLE credentials (
    login_email VARCHAR(255) NOT NULL,
    pswd VARCHAR(255) NOT NULL
);

-- Add credential_id PK and empty user_id column to credentials table
ALTER TABLE credentials ADD credential_id MEDIUMINT UNSIGNED NOT NULL PRIMARY KEY AUTO_INCREMENT FIRST;
ALTER TABLE credentials ADD user_id MEDIUMINT UNSIGNED NOT NULL AFTER credential_id;

-- Update credentials.user_id = users.user_id
UPDATE credentials
JOIN users ON credentials.credential_id = users.user_id
SET credentials.user_id = users.user_id
WHERE credentials.credential_id > 0;

-- Make credentials.user_id into FK
ALTER TABLE credentials
ADD CONSTRAINT creds_fk_user_id FOREIGN KEY (user_id) REFERENCES users (user_id);

-- Table 3: Create address table for second design. After, use filldb to fill with dummy data.
CREATE TABLE address (
    address VARCHAR(255) NOT NULL,
    billing_address VARCHAR(255) NOT NULL
);

-- Add address_id PK to address table
ALTER TABLE address ADD address_id MEDIUMINT UNSIGNED NOT NULL PRIMARY KEY AUTO_INCREMENT FIRST;

-- Table 4: Create user_address linking table, add address_id later
CREATE TABLE user_address (
    user_id MEDIUMINT UNSIGNED NOT NULL,
    address_id MEDIUMINT UNSIGNED NOT NULL DEFAULT 0
);

-- Insert users.user_id into user_address table
INSERT INTO user_address (user_id)
SELECT user_id
FROM users;

-- Make user_address.user_id into FK
ALTER TABLE user_address
ADD CONSTRAINT ua_fk_user_id FOREIGN KEY (user_id) REFERENCES users (user_id);

-- Update user_address.address_id = address.address_id
UPDATE user_address
JOIN address ON user_address.user_id = address.address_id
SET user_address.address_id = address.address_id
WHERE user_address.user_id > 0;

-- Make user_address.address_id into FK
ALTER TABLE user_address
ADD CONSTRAINT ua_fk_address_id FOREIGN KEY (address_id) REFERENCES address (address_id);

-- Table 5: Create orders table. After, use filldb to fill with dummy data.
CREATE TABLE orders (
    order_quantity SMALLINT UNSIGNED NOT NULL
);

-- Add order_no PK and empty user_id column to orders table
ALTER TABLE orders ADD order_no MEDIUMINT UNSIGNED NOT NULL PRIMARY KEY AUTO_INCREMENT FIRST;

-- Table 6: Create user_orders linking table
CREATE TABLE user_orders (
    user_id MEDIUMINT UNSIGNED NOT NULL,
    order_no MEDIUMINT UNSIGNED NOT NULL DEFAULT 0
);

-- Insert users.user_id into user_orders table
INSERT INTO user_orders (user_id)
SELECT user_id
FROM users;

-- Make user_orders.user_id into FK
ALTER TABLE user_orders
ADD CONSTRAINT uo_fk_user_id FOREIGN KEY (user_id) REFERENCES users (user_id);

-- Update user_orders.order_no = orders.order_no
UPDATE user_orders
JOIN orders ON user_orders.user_id = orders.order_no
SET user_orders.order_no = orders.order_no
WHERE user_orders.user_id > 0;

-- Make users_orders.order_no into FK !!!
ALTER TABLE user_orders
ADD CONSTRAINT uo_fk_orders_no FOREIGN KEY (order_no) REFERENCES orders (order_no);

-- Table 7: Create order_address linking table
CREATE TABLE order_address (
    order_no MEDIUMINT UNSIGNED NOT NULL,
    address_id MEDIUMINT UNSIGNED NOT NULL DEFAULT 0
);

-- Insert orders.order_no into order_address table
INSERT INTO order_address (order_no)
SELECT order_no
FROM orders;

-- Make order_address.order_no into FK
ALTER TABLE order_address
ADD CONSTRAINT oa_fk_order_no FOREIGN KEY (order_no) REFERENCES orders (order_no);

-- Update order_address.address_id = address.address_id
UPDATE order_address
JOIN address ON order_address.order_no = address.address_id
SET order_address.address_id = address.address_id
WHERE order_address.order_no > 0;

-- Make order_address.address_id into FK !!!
ALTER TABLE order_address
ADD CONSTRAINT oa_fk_orders_no FOREIGN KEY (address_id) REFERENCES address (address_id);
     
-- TEST QUERIES for SECOND DESIGN:

/* 1. Summarize orders by address
           Duration / Fetch
      -------------------------- 
Run 1:   8.485 sec / 1.437 sec
Run 2:   8.625 sec / 1.422 sec
Run 3:   8.187 sec / 1.531 sec
Run 4:   8.344 sec / 1.453 sec
Run 5:   8.797 sec / 1.406 sec
AVG:    8.4876 sec / 1.4498 sec */
SELECT
    billing_address,
    address,
    o.*
FROM orders o
    LEFT JOIN address a
    ON a.address_id = o.order_no
ORDER BY billing_address;

/* 2. Summarize orders by user
          Duration / Fetch
      -------------------------- 
Run 1:   0.015 sec / 5.047 sec
Run 2:   0.016 sec / 4.203 sec
Run 3:   0.015 sec / 4.234 sec
Run 4:   0.016 sec / 4.969 sec
Run 5:   0.031 sec / 4.25 sec
AVG:    0.0124 sec / 2.6906 sec */
SELECT
    user_id,
    user_first_name,
    o.*
FROM users u
    JOIN orders o ON u.user_id = o.order_no
ORDER BY u.user_id;

-- Remove some nicknames for the third summary query
UPDATE users
SET user_nickname = NULL
WHERE (user_id > 56 AND user_id < 235)
    OR (user_id > 3515 AND user_id < 51681)
    OR (user_id > 81841 AND user_id < 84846)
    OR (user_id > 516518 AND user_id < 651818)
    OR (user_id > 950000 AND user_id < 950515);

/* 3. Count how many users have nicknames
         Duration / Fetch
      -------------------------- 
Run 1:   0.437 sec / 0.000 sec
Run 2:   0.438 sec / 0.000 sec
Run 3:   0.422 sec / 0.000 sec
Run 4:   0.438 sec / 0.000 sec
Run 5:   0.438 sec / 0.000 sec
AVG:    0.4346 sec / 0.000 sec */
SELECT COUNT(user_nickname)
FROM users
WHERE user_nickname IS NOT NULL; -- 812,840 with nicknames

-- Encrypt passwords from users_less table
UPDATE credentials
SET pswd = CONCAT('*', UPPER(SHA1(UNHEX(SHA1(pswd)))))
WHERE credential_id > 0;

/* 4. Log in a user with a valid password (producing the necessary columns an app would need
from this query)
         Duration / Fetch
      -------------------------- 
Run 1:   2.297 sec / 0.000 sec
Run 2:   2.297 sec / 0.000 sec
Run 3:   2.297 sec / 0.000 sec
Run 4:   2.266 sec / 0.000 sec
Run 5:   2.266 sec / 0.000 sec
AVG:    2.2846 sec / 0.000 sec */
SELECT
    cred.user_id,
    login_email,
    pswd AS pswd,
    user_first_name,
    user_nickname
FROM credentials cred
    JOIN users u
        ON cred.credential_id = u.user_id
WHERE pswd = CONCAT('*', UPPER(SHA1(UNHEX(SHA1('glennie68')))));

/* ////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////SUMMARY//////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////////////////////// */
/* ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
                                   AVERAGE TIME OF QUERIES

1. Summarize orders by address:

                                                     Duration / Fetch
                                                  ------------------------
                          First Design Average:   26.1190 sec / 2.5096 sec
                          Second Design Average:   8.4876 sec / 1.4498 sec

   Q: Your comparison of the resulting query response time. Why is one better than the other?
      How would this change if the use case were different?
      
   A: The second design's duration time is more than 3 times faster than the first design, with
      fetch time faster by about 1 sec. The second design has much lower duration and fetch times.
      because it was made to be more efficient by having more and smaller tables that are designated
      to related fields. Included are linking tables for keeping data integrity and not clogging up
      small tables with redundant data during joins. The first design has one big table with seven
      columns and one smaller table with three columns, including a foreign key that references the
      big table's primary key. The first design's query required searching through the entirety of
      the big table and smaller table, which included irrevelant fields. The second design has
      seven small tables, ranging from 2 to 4 columns each. The second design's query required
      mostly searching through relevant data. The average times would be much different depending
      on the query design. Changing the order of selected columns and joins and join types would
      make the second design slower.


2. Summarize orders by user:

                                                      Duration / Fetch
                                                   ------------------------
                           First Design Average:    8.1968 sec / 0.5658 sec
                           Second Design Average:   0.0124 sec / 2.6906 sec

   Q: Your comparison of the resulting query response time. Why is one better than the other?
      How would this change if the use case were different?
   
   A: Second design is more than 8 times faster while first design's fetch time is faster by
      more than 2 seconds, but difference in fetch time doesn't matter in this case. First
      design had to search through all its tables, which required more duration time. Second
      design only needed to search through users and orders columns. The second design could
      have been slower if the order of selected columns and joins were mixed up and made less
      desirable for performance.


3. Count how many users have nicknames:

                                                     Duration / Fetch
                                                  ------------------------
                           First Design Average:   7.3592 sec / 0.000 sec
                           Second Design Average:  0.4346 sec / 0.000 sec

   Q: Your comparison of the resulting query response time. Why is one better than the other?
      How would this change if the use case were different?
   
   A: Second design is about 7 times faster. Fetch times are indistinguishable. Second design
      is better because it only required searching through a table with three columns in
      contrast to the first design, which had 7 columns. If the second design had more columns,
      such as 5, the duration time may be a little slower but not as slow as the first design.
      Also, the query's order of selected columns and joins can cause the second design to
      slow down a little as well.


4. Log in a user with a valid password (producing the necessary columns an app would need
from this query)

                                                     Duration / Fetch
                                                  ------------------------
                           First Design Average:   5.3750 sec / 0.000 sec
                           Second Design Average:  2.2846 sec / 0.000 sec

   Q: Your comparison of the resulting query response time. Why is one better than the other?
      How would this change if the use case were different?
   
   A: Second design was more than 2 times faster than first design. Fetch times are
      indistinguishable. Both designs had to search through 7 columns total. However, the
      second design have 3 columns that were either primary or foreign keys while the
      first design only had 1 column that was a primary key. Overall there was much less
      data to search through in the second design. If the second design had more data to
      go through, the duration time could be slow as the first design, not to mention if
      the order of selected columns and joins were undesirable.

 
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ */