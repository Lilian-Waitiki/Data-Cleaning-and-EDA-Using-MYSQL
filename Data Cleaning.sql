-- Data Cleaning 
SELECT * FROM layoffs;

-- To do;
-- 1. Remove Duplicates
-- 2. Standardize the Data 
-- 3. Null Values or Blank Values
-- 4. Remove any Columns or Rows

CREATE TABLE LayoffsStaging
LIKE layoffs;

SELECT * FROM LayoffsStaging;

-- Duplicating the data from the original layoffs table to help in making the editing in the LayoffsStaging table without altering the original data. 
INSERT INTO LayoffsStaging
SELECT * FROM Layoffs;

-- Task 1. Removing Duplicates
-- First create a unique row identifier (using the window functions).
SELECT *,
ROW_NUMBER() OVER (
	PARTITION BY company, location, industry, percentage_laid_off, `date`) AS row_num
FROM LayoffsStaging;

-- partition by each row to help determine the number duplicates. 
WITH duplicate_cte AS (
	SELECT *,
		ROW_NUMBER() OVER (
			PARTITION BY company, location, industry, total_laid_off, percentage_laid_off, `date`, stage, country, funds_raised_millions) AS row_num
	FROM LayoffsStaging)
SELECT * FROM duplicate_cte 
WHERE row_num >1; 

-- make sure to delete the duplicated values only and not all the rows containing a certain data. 
-- This query will output an error since it is not possible to update a CTE, and in this case, DELETE is a form of an update function. 
WITH duplicate_cte AS (
	SELECT *,
		ROW_NUMBER() OVER (
			PARTITION BY company, location, industry, total_laid_off, percentage_laid_off, `date`, stage, country, funds_raised_millions) AS row_num
	FROM LayoffsStaging)
DELETE FROM duplicate_cte 
WHERE row_num >1; 

-- To remove the duplicate values, copy the data above in a new table and remove the duplicate values from the created table.
-- Using the layoffsstaging, copy to clipboard >  create statement 
CREATE TABLE `layoffs_staging2` (
  `company` text,
  `location` text,
  `industry` text,
  `total_laid_off` int DEFAULT NULL,
  `percentage_laid_off` text,
  `date` text,
  `stage` text,
  `country` text,
  `funds_raised_millions` int DEFAULT NULL,
  `row_num` INT 
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

SELECT * FROM layoffs_staging2;

-- populating the data in the layoffs_staging2 table.
INSERT INTO layoffs_staging2
SELECT *,
		ROW_NUMBER() OVER (
			PARTITION BY company, location, industry, total_laid_off, percentage_laid_off, `date`, stage, country, funds_raised_millions) AS row_num
	FROM LayoffsStaging;

-- Deleting the duplicate values     
SET SQL_SAFE_UPDATES = 0;
DELETE FROM layoffs_staging2
WHERE row_num > 1;

SELECT * FROM layoffs_staging2;
-- It would be easier to remove the duplicates if there as a unique column. Since we did not have that we had to do a work around to delete the duplicate records. 

-- Task 2 Standardize the Data 
-- finding issues in the data and fixing it. 

-- The company column contains white spaces, 
SELECT company, TRIM(company) FROM layoffs_staging2;

-- We need to update the table to remove the white spaces.
UPDATE layoffs_staging2
SET company = TRIM(company);

-- From the industry column, we need to make sure the names are consistent when reffering to the same industry
-- From the query below we can see that the crypto industry is written differently and hence may create confusion.
SELECT DISTINCT industry FROM layoffs_staging2
ORDER BY 1;

SELECT * FROM layoffs_staging2
WHERE industry LIKE 'Crypto%';

-- Therefore, updating the crypto industry is necessary, to create consistency
UPDATE layoffs_staging2
SET industry = 'Crypto'
WHERE industry LIKE 'Crypto%';

-- confirm that the data has been updated succesfully
SELECT DISTINCT industry FROM layoffs_staging2
ORDER BY 1;

-- It is advisable to check column by column to confirm whether there are any issues.
-- The country column 
SELECT DISTINCT country FROM  layoffs_staging2
ORDER BY 1;

-- from the output above, there is an extra row representing the united states
-- Removing the extra country with trailing fullstop. 
SELECT DISTINCT TRIM(TRAILING '.' FROM country)
FROM layoffs_staging2;

UPDATE layoffs_staging2 
SET country = TRIM(TRAILING '.' FROM country)
WHERE country LIKE 'United States%';

-- The date column 
-- change the the text data type to date data type in this column
SELECT `date`, STR_TO_DATE(`date`, '%m/%d/%Y') 
FROM layoffs_staging2;

UPDATE layoffs_staging2 
SET `date` = STR_TO_DATE(`date`, '%m/%d/%Y');

ALTER TABLE layoffs_staging2
MODIFY COLUMN `date` DATE; 

-- Checking the updated table so far 
SELECT * FROM layoffs_staging2;

-- Task 3. Null Values or Blank Values
SELECT * FROM layoffs_staging2 
WHERE total_laid_off IS NULL
	AND percentage_laid_off IS NULL;
    
-- Checking the null and blank values from the industry column
SELECT * 
FROM layoffs_staging2 
WHERE industry IS NULL 
	OR industry = '';

/* We can use the company column to check for the null and blank industry column. This can be done by checking the non-null industry values in a certain company.
By this we will be able to fill the blank industry values using the available company data for example, we would first check the Airbnb company, to see the 
appropriate industry */
SELECT * 
FROM layoffs_staging2 
WHERE company = 'Airbnb';
-- From the above query, it is evident that the Airbnb is from the travel industry. This data can be used to populate the blank industry values in that company.

-- First retrieve the data to check the blank data and which values match to it. This can be done through a self join
SELECT *
FROM layoffs_staging2 AS t1
JOIN layoffs_staging2 t2 
	ON t1.company = t2.company 
    AND t1.location = t2.location 
WHERE (t1.industry IS NULL OR t1.industry = '') 
	AND t2.industry IS NOT NULL;

-- We need to update the data with the already available data
-- But first we need to update the blank industry values to NULL to mak it easier for the query to run. Having the mixture of blank and null values does not update the values correctly.
UPDATE layoffs_staging2 
SET industry = NULL
WHERE industry = '';

-- Updating the data with missing values
UPDATE layoffs_staging2 AS t1
JOIN layoffs_staging2 t2 
	ON t1.company = t2.company 
    AND t1.location = t2.location
SET t1.industry = t2.industry 
WHERE t1.industry IS NULL 
	AND t2.industry IS NOT NULL; 
    
-- This is the total null values we can update since we do not have any extra information.
-- For example, for the total_laid_off and percentage_laid_off, we could only update it, if we had the total numer of employees at the beginning. 
-- In this case, if we had the total employees, it would be easier to calculate the total_laid_off from the given percentage_laid_off. 

-- TASK 4 Remove any Columns or Rows
-- Since we do not need the row_num column anymore, it would be better to delete it at this point
ALTER TABLE layoffs_staging2
DROP COLUMN row_num;

-- Since we will also use the total_laid_off and percentage_laid_off columns a lot in the analysis, the null values in those columns will not be of much help.
-- Therefore we need to drop those rows will null and blank values.
DELETE
FROM layoffs_staging2
WHERE total_laid_off IS NULL 
	AND percentage_laid_off IS NULL; 

-- The final cleaned table:
SELECT * FROM layoffs_staging2;
