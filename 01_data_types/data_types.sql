USE practice;

CREATE TABLE table_1 (
	pk INT NOT NULL AUTO_INCREMENT,
	ch CHAR(100) NULL,
    vc VARCHAR(255) NULL,
    date INT NULL,
	ts TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    dt DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    vb VARBINARY(255) NULL,
    PRIMARY KEY (pk)
);

/* 1. Create a VARCHAR value that has enough spaces at the end
to exceed the value of your CHAR datatype. */
INSERT INTO table_1 (ch, vc)
VALUES ('space', 'space      ');
/* INSERT into the CHAR column the value of the VARCHAR column from the row
with the longer VARCHAR. INSERT into the VARCHAR the value of the CHAR
column. */
INSERT INTO table_1 (ch, vc)
VALUES ('space      ', 'space');
/* Q: What is the size of the value stored in the CHAR column. 
   A: 100 bytes
   
   Q: Did you get an error or warning?
   A: No */

/* 2. Issue the followin statement: */
SELECT TIMESTAMPDIFF(YEAR,makedate('75',1),makedate('47',1));
/* Q: Explain the results
   A: The result is 72 and is not correct because by only
      providing two digits for the year inputs it causes
      confusion and miscalculation since there is no
      guessing which centuries those years are in. Need to
      provide four digit years for accurate results. */

/* 3. Set a CHAR or VARCHAR to a numeric value.
set a numeric column to the value of the char column with the
number as it's */
UPDATE table_1
SET ch = '2021'
WHERE pk = 2;

UPDATE table_1
SET date = ch
WHERE pk = 2;

/* 4. Select * from a few rows.
Update some columns in those rows.
Select * from the same rows.
Explain any changes to your data that weren't related to the
specific columns you were updating. */
-- First, add a few more records/rows to table_1
INSERT INTO table_1 (ch, vc, date)
VALUES ('toast', 'toasty', 2022), ('boat', 'boaty', 2023);

SELECT * 
FROM table_1
WHERE pk IN (3, 4);

UPDATE table_1
SET ch = vc
WHERE pk IN (3, 4);

SELECT *
FROM table_1
WHERE pk IN (3, 4);

/* 5. Insert a row with the following string in the CHAR or VARCHAR field
"this is a string with some text I will search for".
Insert a row with the same string in the BINARY or VARBINARY column.
Execute the following statements (substitute the table and column names
with the appropriate ones for your table:
SELECT * FROM `table_1` WHERE `ch` LIKE '%SOME%';
SELECT * FROM `table_1` WHERE `vb` LIKE '%SOME%'; */
INSERT INTO table_1 (vc)
VALUES ("this is a string with some text I will search for");

INSERT INTO table_1 (vb)
VALUES ("this is a string with some text I will search for");

SELECT * FROM `table_1` WHERE `vc` LIKE '%SOME%';
SELECT * FROM `table_1` WHERE `vb` LIKE '%SOME%';

/* 6. Create various dates in your date columns
Set each date type using values of another data type column value.
SELECT the values you set.
Are the results what you expected? */
INSERT INTO table_1 (date)
VALUES (2024), (2025), (2026);

UPDATE table_1
SET date = dt
WHERE pk IN (7, 8, 9);

/*
Question:
Q: Are the results what your expected?
A: Yes, the result is "Error Code: 1264. Out of range value for column 'date' at row 1".
   That is because the date column s limited to accepting integers/digits.
*/




