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
