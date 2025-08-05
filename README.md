# Layoffs Data Cleaning Project

## Overview
This project documents the process of cleaning and preparing a raw dataset on company layoffs. The goal was to transform the raw data into a structured and standardized format suitable for robust data analysis. All cleaning operations were performed on a staging table to ensure the integrity of the original dataset.

## Source Data
The raw data was initially loaded into a table named `layoffs_staging`. This table contained information on company layoffs, including details such as company name, location, date, total laid off, and more.

## Data Cleaning & Transformation Steps
The following steps were executed to clean and standardize the data, with the final cleaned data residing in a new table, `layoffs_staging2`.

---

### 1. Duplicate Removal
- **Goal:** Ensure each layoff event is represented by a single, unique record.
- **Method:** A temporary column, `row_num`, was added to the data. This column assigned a unique number to each row within groups of identical records, partitioned by all key columns.
- **Result:** All rows with a `row_num` greater than 1 were identified as duplicates. These duplicates were then removed to create a clean, distinct dataset.

---

### 2. Data Standardization
- **Goal:** Fix inconsistencies and normalize data formats for uniform analysis.
- **Method:**
  - **Whitespace:** Leading and trailing spaces from the company names were removed using the `TRIM()` function.
  - **Country Names:** The `country` column was reviewed for spelling mistakes or inconsistencies by selecting and ordering all distinct values.
  - **Date Formats:** The `date` and `date_added` columns, originally stored as text, were converted into a proper `DATE` data type. This enables easy filtering and calculations based on time.

---

### 3. Handling Missing and Inconsistent Values
- **Goal:** Replace blank text values with `NULL` and manually correct specific data points.
- **Method:**
  - **Blank to NULL:** Empty string values (`''`) in the `total_laid_off`, `percentage_laid_off`, and `funds_raised` columns were converted to `NULL` using `NULLIF()`. This is essential for performing accurate mathematical and aggregate calculations.
  - **Manual Correction:** For a few specific companies (e.g., `'Appsmith'`, `'Eyeo'`) where the industry was missing but known, the value was manually updated.
  - **Missing Data Analysis:** Queries were run to count the total number of missing (`NULL`) values for key columns to understand the scope of the problem.

---

### 4. Filtering Out Incomplete Data
- **Goal:** Remove records that lack critical information needed for meaningful analysis.
- **Method:** All rows where either `total_laid_off` or `percentage_laid_off` were `NULL` were deleted from the dataset. This ensures that the remaining data is robust enough for core analysis.

---

### 5. Final Cleanup
- **Goal:** Finalize the table structure by removing temporary columns.
- **Method:** The `row_num` column, which was only used for the deduplication process, was permanently dropped from the `layoffs_staging2` table.

---

## Final Output
The final output is the `layoffs_staging2` table. This table contains a clean, standardized, and well-structured dataset — free of duplicates and inconsistencies — and ready for further exploration and analysis.
