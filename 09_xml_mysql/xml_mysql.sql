-- XML in MySQL
USE practice;

-- Create table with a text field
CREATE TABLE ecommerce_system (
    xml_id TINYINT NOT NULL AUTO_INCREMENT,
    xml_info TEXT,
    PRIMARY KEY (xml_id)
);

-- Store the example XML into a TEXT field
INSERT INTO ecommerce_system (xml_info)
VALUES
("<shiporder orderid=\"889923\"
xmlns:xsi=\"http://www.w3.org/2001/XMLSchema-instance\"
xsi:noNamespaceSchemaLocation=\"shiporder.xsd\">
  <orderperson>John Smith</orderperson>
  <shipto>
    <name>Ola Nordmann</name>
    <address>Langgt 23</address>
    <city>4000 Stavanger</city>
    <country>Norway</country>
  </shipto>
  
  <item>
    <title>Empire Burlesque</title>
    <note>Special Edition</note>
    <quantity>1</quantity>
    <price>10.90</price>
  </item>
  
  <item>
    <title>Hide your heart</title>
    <quantity>1</quantity>
    <price>9.90</price>
  </item>
</shiporder>");
-- ========================================================================================================
/*
Instructions:
1. Create a procedure which extracts the "shipto" name for any shipments going to the country "norway"
   (or "Norway"--should be case insensitive). This is an easy one since there's only one country.
*/
DELIMITER $$
CREATE PROCEDURE extract_shipto_name()
BEGIN
    DECLARE i TINYINT DEFAULT 1;

    -- Since there is only one record for <shipto>, do one loop where i = 1
    WHILE i < 2 DO
        SET @country = (
            SELECT ExtractValue(xml_info, '//shipto[$i]/country')
            FROM ecommerce_system
            WHERE xml_id = 1);

        IF @country = 'Norway' THEN
            SELECT ExtractValue(xml_info, '//shipto[$i]/name') AS shipto_name
            FROM ecommerce_system
            WHERE xml_id = 1;
        END IF;

        -- Cause loop to end since i now equals 2
        SET i = i + 1;
    END WHILE;
END$$
DELIMITER ;

-- Extract name where the country is Norway
CALL extract_shipto_name();
/*
Result:
+--------------+
| shipto_name  |
+--------------+
| Ola Nordmann |
+--------------+

Explanation:
The extract_shipto_name() stored procedure used a while loop, index, and if statement to check if a
<shipto> record had 'Norway' as its country and extracted the name from the matching record. Since
there is just one <shipto> record, I ran the loop once. If there were more records, I could simply
increase the number of loops ran to check all <shipto> records.
*/

-- ========================================================================================================

/*
Instructions:
2. Can you extract titles for any "special edition" books in the order?
*/
DELIMITER $$
CREATE PROCEDURE extract_se_title()
BEGIN
    DECLARE i TINYINT DEFAULT 1;

    -- Since there are just two records for <item>, do two loops
    WHILE i < 3 DO
        SET @note = (
            SELECT ExtractValue(xml_info, '//item[$i]/note')
            FROM ecommerce_system
            WHERE xml_id = 1);
        
        IF @note = 'Special Edition' THEN
            SELECT ExtractValue(xml_info, '//item[$i]/title') AS item_title
            FROM ecommerce_system
            WHERE xml_id = 1;
        END IF;
        
        SET i = i + 1;
    END WHILE;
END$$
DELIMITER ;

-- Extract title where the note indicates Special Edition
CALL extract_se_title();
/*
Result:
+------------------+
| item_title       |
+------------------+
| Empire Burlesque |
+------------------+

Explanation:
Yes, the extract_se_title() stored procedure successfully extracted the <item> title where note is
'Special Edition' by using a while loop, index, and if statement like the previous problem. I set
the while loop to run two loops since there are just two <item> records. The number of loops can
increase depending on how many records there are.
*/

-- ========================================================================================================

/*
Instructions:
3. Can you produce a sum total of the cost of all items in an order?
*/
DELIMITER $$
CREATE PROCEDURE sum_item_price()
BEGIN
    DECLARE i TINYINT DEFAULT 1;
    DECLARE total_price DECIMAL(6,2) DEFAULT 0;

    -- Since there are just two records for <item>, do two loops
    WHILE i < 3 DO
        SET @add_price = (
            SELECT ExtractValue(xml_info, '//item[$i]/price')
            FROM ecommerce_system
            WHERE xml_id = 1);
        
        SET total_price = total_price + @add_price;
        SET i = i + 1;
    END WHILE;

    SELECT total_price;
END$$
DELIMITER ;

-- Extract title where the note indicates Special Edition
CALL sum_item_price();
/*
Result:
+--------------+
| total_price  |
+--------------+
| 20.80        |
+--------------+

Explanation:
Yes, the sum_item_price() stored procedure successfully produced a sum total of the cost of
all items in an order. This was done by a while loop, index, and counter for adding each
<item> record's price to keep track of the total cost.
*/

-- ========================================================================================================