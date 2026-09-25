# Data Cleaning & Validation Pipeline

## Overview

This project contains an R-based data cleaning and validation pipeline for a raw customer orders dataset.

The pipeline reads raw order data from an Excel workbook, applies standardized cleaning and transformation rules, validates the resulting dataset, and produces a cleaned dataset suitable for analysis and reporting.

The workflow is designed to demonstrate a practical data-management process:

**Raw Data → Cleaning → Standardization → Transformation → Validation → Clean Dataset**

---

## Project Structure

```text
.
├── data/
│   └── Data Cleaning Dataset.xlsx
├── scripts/
│   └── data_cleaning.R
└── README.md
```

> The exact file names and folder structure can be adjusted depending on the project setup.

---

## Requirements

The project uses R and the following packages:

* `dplyr` — data manipulation
* `stringr` — string cleaning and pattern matching
* `janitor` — removal of empty rows
* `readxl` — reading Excel workbooks

Install the required packages with:

```r
install.packages(c(
  "dplyr",
  "stringr",
  "janitor",
  "readxl"
))
```

---

## Input Data

The input file is:

```text
data/Data Cleaning Dataset.xlsx
```

The pipeline reads the:

```text
Raw Orders
```

worksheet.

The raw dataset contains information such as:

* Order ID
* Customer Name
* Email
* Phone
* City
* Product
* Quantity
* Unit Price
* Payment Method
* Order Date
* Status
* Rating

---

# Data Cleaning Process

## 1. Remove Empty Rows

Completely empty rows are removed from the raw dataset.

```r
remove_empty(which = "rows")
```

This prevents blank records from being carried into the cleaned dataset.

---

## 2. Email Cleaning

Email values are standardized and invalid email values are converted to `NA`.

The current workflow also replaces the original email domain with:

```text
@example.com
```

This preserves the username portion while anonymizing the original domain.

For example:

```text
john.doe@gmail.com
```

becomes:

```text
john.doe@example.com
```

Invalid values without an `@` are converted to `NA`.

### Important

The email transformation is an **anonymization step**, not simply an email-format correction.

---

## 3. Customer Name Standardization

Customer names are converted to title case.

Where the customer name is missing, the username portion of the email address is used as a fallback.

For example:

```text
john.doe@example.com
```

can be used to derive:

```text
John Doe
```

---

## 4. Phone Number Cleaning

Non-numeric characters are removed from phone numbers.

Kenyan numbers are standardized to the 10-digit format beginning with `0`.

Examples:

```text
254712345678
```

becomes:

```text
0712345678
```

Numbers that do not conform to the expected format are converted to `NA`.

---

## 5. City Standardization

City names are converted to title case and known spelling errors are corrected.

Current corrections include:

| Raw Value | Standard Value |
| --------- | -------------- |
| Kissumu   | Kisumu         |
| Mombassa  | Mombasa        |
| Niarobi   | Nairobi        |

The lookup is maintained in:

```r
city_fixes
```

This makes additional city corrections easy to add.

---

## 6. Product Standardization

Product names are cleaned by:

* removing unnecessary whitespace
* standardizing capitalization
* correcting known product-name variations

Current corrections include:

| Raw Value    | Standard Value      |
| ------------ | ------------------- |
| USB variants | USB Flash Drive     |
| External Hdd | External Hard Drive |
| Lap Top      | Laptop              |
| Head Phones  | Headphones          |
| Desktop Pc   | Desktop PC          |

---

## 7. Product Categorization

Products are assigned to broad categories based on product names.

Current categories include:

* Computers
* Electronics
* Office Equipment
* Accessories

Examples:

```text
Laptop → Computers
Monitor → Electronics
Printer → Office Equipment
```

Products that do not match the defined rules are assigned to:

```text
Accessories
```

---

## 8. Quantity Cleaning

Invalid quantity values are converted to `NA`.

The following values are treated as invalid:

* quantities less than or equal to zero
* `999`, which is a known placeholder/error value in the source dataset

For example:

```text
Quantity = 999
```

becomes:

```text
NA
```

---

## 9. Unit Price Standardization

Unit prices are converted to numeric values using `parse_number()`.

Where a price contains `$`, it is treated as USD and converted to Kenyan Shillings.

The current exchange rate is:

```r
USD_TO_KES <- 130
```

For example:

```text
$100
```

becomes:

```text
KES 13,000
```

Prices without `$` are assumed to already be in Kenyan Shillings.

### Important assumption

The pipeline currently assumes:

```text
$ = USD
```

and that non-USD values are already in KES.

The exchange rate should therefore be updated whenever the source dataset uses a different conversion rate.

---

## 10. Payment Method Standardization

Payment method values are standardized into consistent labels.

Examples include:

```text
CC
Credit Card
```

→

```text
Credit Card
```

and:

```text
Mobile
Pesa
```

→

```text
M-Pesa
```

---

## 11. Order Status Standardization

Order statuses are standardized into the following categories:

* Cancelled
* Completed
* Returned
* Pending

Pattern matching is case-insensitive.

For example:

```text
Order Cancelled
CANCELLED
cancelled
```

are standardized to:

```text
Cancelled
```

---

## 12. Rating Cleaning

Ratings are converted to numeric values.

The text value:

```text
five
```

is converted to:

```text
5
```

`N/A` values are converted to `NA`.

The resulting rating is expected to fall between:

```text
1 and 5
```

---

# Data Validation

After cleaning, the dataset is subjected to data-quality checks using `stopifnot()`.

The validation layer checks:

### Order IDs

* Order IDs must not be missing.
* Order IDs must be unique.

### Email

Valid email values must follow the expected email structure.

### Phone

Valid phone numbers must contain 10 digits and begin with `0`.

### Quantity

Valid quantities must be greater than zero.

### Unit Price

Valid prices must be greater than or equal to zero.

### Rating

Ratings must be between 1 and 5.

### Status

Status values must be one of:

```text
Cancelled
Completed
Returned
Pending
```

Missing values are allowed where appropriate.

If any validation rule fails, `stopifnot()` stops execution.

This prevents an invalid dataset from silently progressing through the workflow.

---

# Output Dataset

The cleaned dataset contains the following fields:

```text
Order ID
Customer_Name
Email
Phone
City
Product
Category
Quantity
Unit Price
Payment Method
Order Date
Status
Rating
```

The original raw customer-name field is replaced with the standardized:

```text
Customer_Name
```

---

# Data Quality Philosophy

The pipeline follows four main principles:

### 1. Standardize

Different representations of the same value should be converted into a common format.

Example:

```text
Mombassa
MOMBASSA
mombassa
```

should ultimately represent:

```text
Mombasa
```

### 2. Correct

Known data-entry errors are corrected using explicit rules or lookup tables.

### 3. Validate

The cleaned data is checked against expected business and structural rules.

### 4. Preserve Transparency

Cleaning rules are explicitly defined in the script rather than making undocumented manual changes to the dataset.

---

# Important Assumptions

The pipeline currently assumes:

1. The source data is contained in the `Raw Orders` worksheet.
2. Order IDs should be unique.
3. Phone numbers are Kenyan numbers.
4. Twelve-digit Kenyan phone numbers use the `254` country code.
5. `$` values represent USD.
6. Non-dollar unit prices are already in KES.
7. The USD/KES conversion rate is `130`.
8. `999` is an invalid quantity placeholder.
9. Ratings range from 1 to 5.
10. The defined order statuses are the accepted statuses.
11. Email domains are intentionally replaced with `example.com` for anonymization.

These assumptions should be reviewed whenever the source dataset or business requirements change.

---

# Recommended Workflow

The recommended execution sequence is:

```text
1. Load raw Excel data
          ↓
2. Remove empty rows
          ↓
3. Standardize text fields
          ↓
4. Clean email and phone fields
          ↓
5. Correct known spelling errors
          ↓
6. Standardize products and categories
          ↓
7. Clean quantities and prices
          ↓
8. Standardize payment methods and status
          ↓
9. Clean ratings
          ↓
10. Select final variables
          ↓
11. Run validation checks
          ↓
12. Use validated dataset for analysis/reporting
```

---

# Future Improvements

Potential improvements to the pipeline include:

* Generate a formal data-quality report showing the number of errors by variable.
* Produce a separate table containing records that failed validation.
* Move product corrections into an external lookup table.
* Move city corrections into an external lookup table.
* Add validation for missing order dates.
* Add date-range validation.
* Add currency as an explicit field if multiple currencies are introduced.
* Create automated summary reports after cleaning.
* Export the validated dataset to Excel/CSV for downstream analysis.
* Add automated tests using a package such as `testthat` as the project grows.

---

# Purpose of the Project

This project demonstrates a reproducible approach to preparing operational data for analysis.

Rather than manually correcting the Excel file, the cleaning rules are encoded in R so that the same process can be repeated whenever new raw data is received.

The approach is therefore:

**Reproducible → Auditable → Validated → Ready for Analysis**
