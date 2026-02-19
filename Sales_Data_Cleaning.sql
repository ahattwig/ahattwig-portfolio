#Dataset is .csv rom https://www.kaggle.com/datasets/ahmedmohamed2003/cafe-sales-dirty-data-for-cleaning-training

#Using Table Data Import Wizard in MySQL Workbench with default values will only import 9006 out of the 10,000 rows

# After setting all data types to text, Table Data Import Wizard imported all 10,000 rows

# Initial examination of imported data
SELECT * 
FROM cafe_sales
;


# changing column names for ease of querying
ALTER TABLE cafe_sales
RENAME COLUMN `Transaction ID` TO `Sale_ID`,
RENAME COLUMN `Price Per Unit` TO `Price`,
RENAME COLUMN `Total Spent` TO `Total_Spent`,
RENAME COLUMN `Payment Method` TO `Payment_Method`,
RENAME COLUMN `Transaction Date` TO `Sale_Date`
;

# Looking at changed columns
SELECT * 
FROM cafe_sales
LIMIT 10
;

# Looking for duplicate IDs (there were none)
SELECT Sale_ID, COUNT(Sale_ID)
FROM cafe_sales
GROUP BY Sale_ID
HAVING COUNT(Sale_ID) > 1
;

# Looking for non-standard character length in ID (there were none)
SELECT Sale_ID, CHAR_LENGTH(Sale_ID)
FROM cafe_sales
GROUP BY Sale_ID
HAVING CHAR_LENGTH(Sale_ID) <> 11
;

# Besides entries with "ERROR", "UNKNOWN", and blanks, other standardization issues are not present with the data

#Looking at rows with Item problems
SELECT *
FROM cafe_sales
WHERE Item = 'UNKNOWN'
OR Item = 'ERROR'
OR Item = ''
;

# Counting the rows with Item problems (there were 969)
SELECT COUNT(Sale_ID)
FROM cafe_sales
WHERE Item = 'UNKNOWN'
OR Item = 'ERROR'
OR Item = ''
;

# consolidating Item problems into nulls (so they don't get included in COUNT, can be used in COALESCE, etc.)
UPDATE cafe_sales
SET Item = NULL
WHERE Item = 'UNKNOWN'
OR Item = 'ERROR'
OR ITEM = ''
;

#Looking at, and counting, rows with Price problems (there are 533)
SELECT *
FROM cafe_sales
WHERE Price = 'UNKNOWN'
OR Price = 'ERROR'
OR Price = ''
;
SELECT COUNT(Sale_ID)
FROM cafe_sales
WHERE Price = 'UNKNOWN'
OR Price = 'ERROR'
OR Price = ''
;

# consolidating Price problems into nulls 
UPDATE cafe_sales
SET Price = NULL
WHERE Price = 'UNKNOWN'
OR Price = 'ERROR'
OR Price = ''
;

# Is it possible to reconstruct missing Item values by looking at Price values, and vice-versa?
SELECT DISTINCT(Item), Price
FROM cafe_sales
WHERE Item IS NOT NULL 
AND PRICE IS NOT NULL 
ORDER BY Price ASC
;
# Cookie	1.0
# Tea		1.5
# Coffee	2.0
# Cake		3.0
# Juice		3.0
# Sandwich	4.0
# Smoothie	4.0
# Salad		5.0
# These results can be used to reconstruct many of the null values in Item and Price

#--------------
# Null Items priced 1.0 can be filled in as Cookie
SELECT Item, Price
FROM cafe_sales
WHERE Item IS NULL
AND Price = '1.0'
;
UPDATE cafe_sales
SET Item = 'Cookie'
WHERE Price = '1.0'
AND ITEM IS NULL
;
# Likewise null Price for Cookie can be filled in as 1.0
SELECT Item, Price
FROM cafe_sales
WHERE Price IS NULL
AND Item = 'Cookie'
;
UPDATE cafe_sales
SET Price = '1.0'
WHERE Item = 'Cookie'
AND Price IS NULL
;
# Double-checking all Cookies are 1.0 and vice-versa
SELECT DISTINCT(Item), Price
FROM cafe_sales
WHERE Item = 'Cookie'
OR Price = '1.0'
;

#--------------------------
# Same process for Item = Tea and Price = 1.5
SELECT Item, Price
FROM cafe_sales
WHERE Item IS NULL
AND Price = '1.5'
;

UPDATE cafe_sales
SET Item = 'Tea'
WHERE Price = '1.5'
AND ITEM IS NULL
;

SELECT Item, Price
FROM cafe_sales
WHERE Price IS NULL
AND Item = 'Tea'
;

UPDATE cafe_sales
SET Price = '1.5'
WHERE Item = 'Tea'
AND Price IS NULL
;
# Double-checking all Teas are 1.5 and vice-versa
SELECT DISTINCT(Item), Price
FROM cafe_sales
WHERE Item = 'Tea'
OR Price = '1.5'
;

#--------------------------------------
# Same process for Item = Coffee and Price = 2.0 (We'll forego doing the SELECT prior to the UPDATE in the interest of brevity)
UPDATE cafe_sales
SET Item = 'Coffee'
WHERE Price = '2.0'
AND ITEM IS NULL
;
UPDATE cafe_sales
SET Price = '2.0'
WHERE Item = 'Coffee'
AND Price IS NULL
;
# Double-checking all Coffees are 2.0 and vice-versa
SELECT DISTINCT(Item), Price
FROM cafe_sales
WHERE Item = 'Coffee'
OR Price = '2.0'
;

#--------------------------------------
# Same process for Item = Salad and Price = 5.0
UPDATE cafe_sales
SET Item = 'Salad'
WHERE Price = '5.0'
AND ITEM IS NULL
;
UPDATE cafe_sales
SET Price = '5.0'
WHERE Item = 'Salad'
AND Price IS NULL
;
# Double-checking all Salads are 5.0 and vice-versa
SELECT DISTINCT(Item), Price
FROM cafe_sales
WHERE Item = 'Salad'
OR Price = '5.0'
;

#--------------------------------------
# Since both Cake and Juice cost 3.0, we cannot reconstruct null items from that price, but we can reconstuct the price for those items
UPDATE cafe_sales
SET Price = '3.0'
WHERE Price IS NULL
AND (Item = 'Cake' OR Item = 'Juice')
;
# Double-checking all Cakes and Juices cost 3.0
SELECT DISTINCT(Item), Price
FROM cafe_sales
WHERE Item = 'Cake'
OR Item = 'Juice'
;

#--------------------------------------
# Likewise Sandwich and Smoothie both cost 4.0, so we can't reconstruct null items from that price, but we can reconstuct the price for those items
UPDATE cafe_sales
SET Price = '4.0'
WHERE Price IS NULL
AND (Item = 'Sandwich' OR Item = 'Smoothie')
;
# Double-checking all Sandwiches and Smoothies cost 4.0
SELECT DISTINCT(Item), Price
FROM cafe_sales
WHERE Item = 'Sandwich'
OR Item = 'Smoothie'
;

# Are all Price values should be filled in now? Let's check 
SELECT COUNT(Sale_ID)
FROM cafe_sales
WHERE Price IS NULL
;
# No, there are still 54 null Price values, let's look closer
SELECT *
FROM cafe_sales
WHERE Price IS NULL
;
# The null Price values come from rows where the Item is also null.

# Perhaps they can reconstructed via dividing Total_Spent by Quantity, in rows where both are available
# First let's consolidate the ERROR, UNKNOWN and blank values in Total_Spent and Quantity to nulls
UPDATE cafe_sales
SET Quantity = NULL
WHERE Quantity = 'UNKNOWN'
OR Quantity = 'ERROR'
OR Quantity = ''
;
UPDATE cafe_sales
SET Total_Spent = NULL
WHERE Total_Spent = 'UNKNOWN'
OR Total_Spent = 'ERROR'
OR Total_Spent = ''
;
# Reconstructing Price value from Total_Spent/Quantity where possible (this changed 48 rows)
UPDATE cafe_sales
SET Price = Total_Spent/Quantity
WHERE Price IS NULL
AND Total_Spent IS NOT NULL
AND Quantity IS NOT NULL
;

# Examining null values in Quantity (479 rows)
SELECT *
FROM cafe_sales
WHERE Quantity IS NULL
;
SELECT COUNT(Sale_ID)
FROM cafe_sales
WHERE Quantity IS NULL
;

# Reconstructing Quantity value from Total_Spent/Price where possible (this changed 456 rows)
UPDATE cafe_sales
SET Quantity = Total_Spent/Price
WHERE Quantity IS NULL
AND Total_Spent IS NOT NULL
AND Price IS NOT NULL
;

# Examining null values in Total_Spent (502 rows)
SELECT *
FROM cafe_sales
WHERE Total_Spent IS NULL
;
SELECT COUNT(Sale_ID)
FROM cafe_sales
WHERE Total_Spent IS NULL
;
# Reconstructing Total_Spent value from Quantity * Price where possible (this changed 479 rows)
UPDATE cafe_sales
SET Total_Spent = Quantity * Price
WHERE Total_Spent IS NULL
AND Quantity IS NOT NULL
AND Price IS NOT NULL
;

# Looking at rows that still have nulls in the 4 columns we've dealt with
SELECT *
FROM cafe_sales
WHERE Item IS NULL
OR Quantity IS NULL
OR Price IS NULL
OR Total_Spent IS NULL
;

# There are some Item values we can populate with new Prices we derived from Total_Spent/Quantity
# So we'll update those (changed 4 rows for Cookie, 8 rows for Tea, 7 rows for Coffee, 2 rows for Salad)
UPDATE cafe_sales
SET Item = 'Cookie'
WHERE Price = '1'
AND ITEM IS NULL
;
UPDATE cafe_sales
SET Item = 'Tea'
WHERE Price = '1.5'
AND ITEM IS NULL
;
UPDATE cafe_sales
SET Item = 'Coffee'
WHERE Price = '2'
AND ITEM IS NULL
;
UPDATE cafe_sales
SET Item = 'Salad'
WHERE Price = '5'
AND ITEM IS NULL
;

# Changing Text data type in Quantity to Int
ALTER TABLE cafe_sales 
MODIFY Quantity Int
;

# Changing Text data type in Price and Total_Spent to Decimal
ALTER TABLE cafe_sales 
MODIFY Price Decimal(5,2)
;

ALTER TABLE cafe_sales 
MODIFY Total_Spent Decimal(5,2)
;

# Looking again at rows with nulls in these 4 columns
SELECT *
FROM cafe_sales
WHERE Item IS NULL
OR Quantity IS NULL
OR Price IS NULL
OR Total_Spent IS NULL
;

SELECT COUNT(Sale_ID)
FROM cafe_sales
WHERE Item IS NULL
OR Quantity IS NULL
OR Price IS NULL
OR Total_Spent IS NULL
;
# What remains are null Items in the 3 to 4 dollar price range, 
# or rows where at least 2 of Quantity, Price, or Total_Spent are null
# Accordingly these values cannot be further reconstructed.

# Changing UNKNOWN, ERROR, and blanks in Payment_Method, Location and Sale_Date columns to NULL
UPDATE cafe_sales
SET Payment_Method = NULL
WHERE Payment_Method = 'UNKNOWN'
OR Payment_Method = 'ERROR'
OR Payment_Method = ''
;
UPDATE cafe_sales
SET Location = NULL
WHERE Location = 'UNKNOWN'
OR Location = 'ERROR'
OR Location = ''
;
UPDATE cafe_sales
SET Sale_Date = NULL
WHERE Sale_Date = 'UNKNOWN'
OR Sale_Date = 'ERROR'
OR Sale_Date = ''
;

# Changing the data type of Sale_date to Date
ALTER TABLE cafe_sales 
MODIFY Sale_Date DATE
;

# Looking at rows where these last 3 columns are null; no obvious way to reconstruct data unfortunately
SELECT *
FROM cafe_sales
WHERE Payment_Method IS NULL
OR Location IS NULL
OR Sale_Date IS NULL
;

# Now to look more broadly at the data, to see how many rowss are complete,
# and to evaluate whether any rows are missing so much data that they should be deleted

SELECT *
FROM cafe_sales
WHERE Payment_Method IS NOT NULL
AND Location IS NOT NULL
AND Sale_Date IS NOT NULL
AND Item IS NOT NULL
AND Quantity IS NOT NULL
AND Price IS NOT NULL
AND Total_Spent IS NOT NULL
ORDER BY Sale_ID ASC
;

SELECT *
FROM cafe_sales
WHERE Payment_Method IS NULL
OR Location IS NULL
OR Sale_Date IS NULL
OR Item IS NULL
OR Quantity IS NULL
OR Price IS NULL
OR Total_Spent IS NULL
ORDER BY Sale_ID ASC
;
# Although 6229 rows have one or more NULLs, all the rows have at least some useful and prima fasciae valid data.
# My inclination is to not delete them.
