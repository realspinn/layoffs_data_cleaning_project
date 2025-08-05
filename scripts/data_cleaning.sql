-- =====================================================================================
-- Data Cleansing Script for Layoffs Data
-- Purpose: To clean and standardize the 'layoffs' dataset for analysis.
-- =====================================================================================

-- Step 1: Identify and Handle Duplicates
-- We're looking for exact duplicate rows based on several key columns.
-- This helps ensure each layoff event is counted only once.
WITH duplicate_cte AS (
    SELECT
        *,
        -- Assigns a row number to each row within groups of identical records.
        -- If 'row_num' is greater than 1, it means it's a duplicate.
        ROW_NUMBER() OVER (PARTITION BY company, location, total_laid_off, 'date', percentage_laid_off, industry, source, stage, funds_raised, country, date_added) AS row_num
    FROM
        layoffs_staging
)
SELECT
    *
FROM
    duplicate_cte
WHERE
    row_num > 1; -- Show us any rows that are duplicates (ideally, this query should return no results after cleaning).

-- Step 2: Create a Staging Table for Cleaning
-- We create a new table to perform our cleaning operations.
-- This is a safe practice so we don't directly modify the original raw data.
CREATE TABLE `layoffs_staging2` (
    `company` text,
    `location` text,
    `total_laid_off` text,
    `date` text,
    `percentage_laid_off` text,
    `industry` text,
    `source` text,
    `stage` text,
    `funds_raised` text,
    `country` text,
    `date_added` text,
    `row_num` INT -- This column will temporarily store the row number for duplicate identification.
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

-- Insert data from the original staging table into our new cleaning table.
-- We're also recalculating the row numbers here to ensure accuracy in the new table.
INSERT INTO layoffs_staging2
SELECT
    *,
    ROW_NUMBER() OVER (PARTITION BY company, location, total_laid_off, 'date', percentage_laid_off, industry, source, stage, funds_raised, country, date_added) AS row_num
FROM
    layoffs_staging;

-- Step 3: Standardize Text Data (e.g., remove extra spaces, fix inconsistencies)

-- Check for any leading or trailing spaces in the 'company' names.
SELECT
    company,
    TRIM(company) -- Shows how the company name would look after trimming spaces.
FROM
    layoffs_staging2;

-- Update the 'company' column to remove any extra spaces.
UPDATE layoffs_staging2
SET
    company = TRIM(company);

-- Check all unique 'country' names to identify any spelling mistakes or inconsistencies.
SELECT DISTINCT
    country
FROM
    layoffs_staging2
ORDER BY
    1; -- Order alphabetically for easier review.

-- Step 4: Standardize Date Formats
-- Convert the 'date' column from text to a proper date format.
-- This makes it easier to perform date-based calculations and filtering.
SELECT
    date,
    STR_TO_DATE(date, '%m/%d/%Y') -- Converts text like '03/01/2023' into a date format.
FROM
    layoffs_staging2;

-- Apply the date conversion to the 'date' column in the table.
UPDATE layoffs_staging2
SET
    date = STR_TO_DATE(date, '%m/%d/%Y');

-- Convert the 'date_added' column from text to a proper date format.
-- Note: The original query used a fixed date '2022-12-16'. This might need adjustment
-- if 'date_added' should be derived from the actual data in the column.
SELECT
    date_added,
    STR_TO_DATE('2022-12-16', '%Y-%m-%d') -- Converts text like 'YYYY-MM-DD' into a date format.
FROM
    layoffs_staging2;

-- Apply the date conversion to the 'date_added' column in the table.
UPDATE layoffs_staging2
SET
    date_added = STR_TO_DATE(date_added, '%Y-%m-%d'); -- Assuming date_added column contains dates in 'YYYY-MM-DD' format.

-- Change the data type of the 'date' column to DATE.
-- This ensures the column stores dates correctly and efficiently.
ALTER TABLE layoffs_staging2
MODIFY COLUMN date DATE;

-- Change the data type of the 'date_added' column to DATE.
-- This ensures the column stores dates correctly and efficiently.
ALTER TABLE layoffs_staging2
MODIFY COLUMN date_added DATE;

-- Step 5: Handle NULL or Blank Values
-- Blank strings ('') are not the same as NULLs in a database.
-- We'll convert blank strings to NULL for better data handling and analysis.

-- Find rows where 'industry' is an empty string.
SELECT
    *
FROM
    layoffs_staging2
WHERE
    industry = '';

-- Manually update specific blank 'industry' values based on known information.
-- This is for specific cases where we know the correct industry.
UPDATE layoffs_staging2
SET
    industry = 'Software Development'
WHERE
    company = 'Appsmith';

UPDATE layoffs_staging2
SET
    industry = 'Software Development'
WHERE
    company = 'Eyeo';

-- Convert empty strings (after trimming spaces) in numeric columns to NULL.
-- This is crucial for calculations, as empty strings can cause errors.
UPDATE layoffs_staging2
SET
    total_laid_off = NULLIF(TRIM(total_laid_off), ''), -- If 'total_laid_off' is blank or just spaces, make it NULL.
    percentage_laid_off = NULLIF(TRIM(percentage_laid_off), ''), -- Same for 'percentage_laid_off'.
    funds_raised = NULLIF(TRIM(funds_raised), '') -- Same for 'funds_raised'.
WHERE
    TRIM(total_laid_off) = '' -- Apply this update only to rows where these fields are blank.
    OR TRIM(percentage_laid_off) = ''
    OR TRIM(funds_raised) = '';

-- Verify if there are any rows left where all three key numeric fields are blank.
SELECT
    *
FROM
    layoffs_staging2
WHERE
    total_laid_off = ''
    AND percentage_laid_off = ''
    AND funds_raised = '';

-- Count how many records have missing 'total_laid_off' values.
SELECT
    COUNT(*) AS missing_total_laid_off
FROM
    layoffs_staging2
WHERE
    total_laid_off IS NULL; -- Now checking for IS NULL after the update.

-- Count how many records have missing 'funds_raised' values.
SELECT
    COUNT(*) AS missing_funds_raised
FROM
    layoffs_staging2
WHERE
    funds_raised IS NULL; -- Now checking for IS NULL after the update.

-- Count how many records have missing 'percentage_laid_off' values.
SELECT
    COUNT(*) AS missing_percentage_laid_off
FROM
    layoffs_staging2
WHERE
    percentage_laid_off IS NULL; -- Now checking for IS NULL after the update.

-- Get a summary of missing values for key numeric columns across the entire dataset.
SELECT
    COUNT(*) AS total_records,
    SUM(CASE WHEN total_laid_off IS NULL THEN 1 ELSE 0 END) AS total_laid_off_missing,
    SUM(CASE WHEN percentage_laid_off IS NULL THEN 1 ELSE 0 END) AS percentage_laid_off_missing,
    SUM(CASE WHEN funds_raised IS NULL THEN 1 ELSE 0 END) AS funds_raised_missing
FROM
    layoffs_staging2; 

-- Step 6: Remove Rows with Insufficient Data
-- Delete rows where critical information (like total laid off or percentage laid off) is missing.
-- These rows might not be useful for our analysis.
DELETE FROM layoffs_staging2
WHERE
    total_laid_off IS NULL
    OR percentage_laid_off IS NULL; -- Removed funds_raised from this criteria as it might not be as critical for all analyses.

-- Display all remaining records after cleaning.
SELECT
    *
FROM
    layoffs_staging2;

-- Step 7: Final Cleanup (Remove Temporary Columns)
-- Remove the 'row_num' column as it was only used for identifying duplicates during cleaning.
ALTER TABLE layoffs_staging2
DROP COLUMN row_num;
