SELECT * 
FROM cafe_sales
;

# Creating the procedure
DELIMITER $$
DROP PROCEDURE IF EXISTS Copy_and_Clean_Data;
CREATE PROCEDURE Copy_and_Clean_Data()
BEGIN
# Creating the table
CREATE TABLE IF NOT EXISTS `cafe_sales_cleaned` (
  `Sale_ID` text,
  `Item` text,
  `Quantity` int DEFAULT NULL,
  `Price` decimal(5,2) DEFAULT NULL,
  `Total_Spent` decimal(5,2) DEFAULT NULL,
  `Payment_Method` text,
  `Location` text,
  `Sale_Date` date DEFAULT NULL,
  `TimeStamp` TIMESTAMP DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

# Copying the data to the new table
INSERT INTO cafe_sales_cleaned
    SELECT *, CURRENT_TIMESTAMP
    FROM cafe_sales;
    
# Data Cleaning Steps
	# Changing UNKNOWN, ERROR, and blank fields into NULLs
		UPDATE cafe_sales
		SET Item = NULL
		WHERE Item = 'UNKNOWN' OR Item = 'ERROR' OR ITEM = ''
		;
		UPDATE cafe_sales
		SET Price = NULL
		WHERE Price = 'UNKNOWN' OR Price = 'ERROR' OR Price = ''
		;
        UPDATE cafe_sales
		SET Quantity = NULL
		WHERE Quantity = 'UNKNOWN' OR Quantity = 'ERROR' OR Quantity = ''
		;
		UPDATE cafe_sales
		SET Total_Spent = NULL
		WHERE Total_Spent = 'UNKNOWN' OR Total_Spent = 'ERROR' OR Total_Spent = ''
		;
        UPDATE cafe_sales
		SET Payment_Method = NULL
		WHERE Payment_Method = 'UNKNOWN' OR Payment_Method = 'ERROR' OR Payment_Method = ''
		;
		UPDATE cafe_sales
		SET Location = NULL
		WHERE Location = 'UNKNOWN' OR Location = 'ERROR' OR Location = ''
		;
		UPDATE cafe_sales
		SET Sale_Date = NULL
		WHERE Sale_Date = 'UNKNOWN' OR Sale_Date = 'ERROR' OR Sale_Date = ''
		;
    # Filling in NULLs with data when possible
		UPDATE cafe_sales
		SET Price = Total_Spent/Quantity
		WHERE Price IS NULL AND Total_Spent IS NOT NULL AND Quantity IS NOT NULL
		;
		UPDATE cafe_sales
		SET Price = '1.0'
		WHERE Item = 'Cookie' AND Price IS NULL
		;
		UPDATE cafe_sales
		SET Price = '1.5'
		WHERE Item = 'Tea' AND Price IS NULL
		;
		UPDATE cafe_sales
		SET Price = '2.0'
		WHERE Item = 'Coffee' AND Price IS NULL
		;
		UPDATE cafe_sales
		SET Price = '5.0'
		WHERE Item = 'Salad' AND Price IS NULL
		;
		UPDATE cafe_sales
		SET Price = '3.0'
		WHERE Price IS NULL AND (Item = 'Cake' OR Item = 'Juice')
		;
		UPDATE cafe_sales
		SET Price = '4.0'
		WHERE Price IS NULL AND (Item = 'Sandwich' OR Item = 'Smoothie')
		;
		UPDATE cafe_sales
		SET Item = 'Cookie'
		WHERE Price = '1.0' AND ITEM IS NULL
		;
		UPDATE cafe_sales
		SET Item = 'Tea'
		WHERE Price = '1.5' AND ITEM IS NULL
		;
        UPDATE cafe_sales
		SET Item = 'Coffee'
		WHERE Price = '2.0' AND ITEM IS NULL
		;
		UPDATE cafe_sales
		SET Item = 'Salad'
		WHERE Price = '5.0' AND ITEM IS NULL
		;
        UPDATE cafe_sales
		SET Quantity = Total_Spent/Price
		WHERE Quantity IS NULL AND Total_Spent IS NOT NULL AND Price IS NOT NULL
		;
        UPDATE cafe_sales
		SET Total_Spent = Quantity * Price
		WHERE Total_Spent IS NULL AND Quantity IS NOT NULL AND Price IS NOT NULL
		;
    
    END $$
DELIMITER ;

# running the procedure
CALL Copy_and_Clean_Data;

# scheduling the procedure
CREATE EVENT run_data_cleaning
	ON SCHEDULE EVERY 30 DAY
    DO CALL Copy_and_Clean_Data();
