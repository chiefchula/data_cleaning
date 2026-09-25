library(dplyr) 
library(stringr) 
library(janitor) 
library(readxl)

# Lookups ------------------
USD_TO_KES <- 130
city_fixes <- c(Kissumu = "Kisumu", Mombassa = "Mombasa", Niarobi = "Nairobi")

raw <- read_excel("data/Data Cleaning Dataset.xlsx", sheet = "Raw Orders")

clean <- raw |>
  remove_empty(which = "rows") |>
  mutate(
    Email = if_else(
      str_detect(Email, "@", negate = TRUE),
      NA_character_,
      paste0(str_to_lower(str_extract(Email, "^[^@]+")), "@example.com")
    ),
    Customer_Name = str_to_title(coalesce(
      `Customer Name`,
      str_replace_all(str_extract(Email, "^[^@]+"), "\\.", " ")
    )),
    Phone = str_remove_all(Phone, "\\D"),
    Phone = case_when(
      str_length(Phone) == 12 ~ paste0("0", str_sub(Phone, 4, 12)),
      str_length(Phone) == 10 ~ Phone,
      TRUE ~ NA_character_
    ),
    City = str_to_title(City),
    City = coalesce(city_fixes[City], City),
    Product = str_squish(str_to_title(Product)),
    Product = case_when(
      str_detect(Product, "^Usb") ~ "USB Flash Drive",
      Product == "External Hdd" ~ "External Hard Drive",
      Product == "Lap Top" ~ "Laptop",
      Product == "Head Phones" ~ "Headphones",
      Product == "Desktop Pc" ~ "Desktop PC",
      TRUE ~ Product
    ),
    Category = case_when(
      str_detect(Product, "Desktop|Laptop|Tablet") ~ "Computers",
      str_detect(Product, "Monitor") ~ "Electronics",
      str_detect(Product, "Printer") ~ "Office Equipment",
      TRUE ~ "Accessories"
    ),
    # 999 is a known placeholder/error value in the source dataset
    Quantity = if_else(Quantity <= 0 | Quantity == 999, NA_real_, Quantity),
    `Unit Price` = parse_number(`Unit Price`) *
      if_else(str_detect(`Unit Price`, "\\$"), USD_TO_KES, 1),
    `Payment Method` = str_squish(str_to_title(`Payment Method`)),
    `Payment Method` = case_when(
      str_detect(`Payment Method`, "Cc|Credit Card") ~ "Credit Card",
      str_detect(`Payment Method`, "Mobile|Pesa") ~ "M-Pesa",
      TRUE ~ `Payment Method`
    ),
    Status = case_when(
      str_detect(Status, regex("cancel", ignore_case = TRUE)) ~ "Cancelled",
      str_detect(Status, regex("complete", ignore_case = TRUE)) ~ "Completed",
      str_detect(Status, regex("return", ignore_case = TRUE)) ~ "Returned",
      str_detect(Status, regex("pending", ignore_case = TRUE)) ~ "Pending",
      TRUE ~ Status
    ),
    Rating = as.numeric(case_when(
      as.character(Rating) == "N/A" ~ NA_character_,
      as.character(Rating) == "five" ~ "5",
      TRUE ~ as.character(Rating)
    ))
  ) |>
  select(`Order ID`, Customer_Name, Email, Phone, City, Product, Category,
         Quantity, `Unit Price`, `Payment Method`, `Order Date`, Status, Rating) |> 
  distinct(`Order ID`, .keep_all = TRUE)

# validation
stopifnot(
  !anyDuplicated(clean$`Order ID`),
  
  all(is.na(clean$Email) |
        str_detect(clean$Email, "^[^@\\s]+@[^@\\s]+\\.[^@\\s]+$")),
  
  all(is.na(clean$Phone) |
        str_detect(clean$Phone, "^0\\d{9}$")),
  
  all(is.na(clean$Quantity) |
        clean$Quantity > 0),
  
  all(is.na(clean$`Unit Price`) |
        clean$`Unit Price` >= 0),
  
  all(is.na(clean$Rating) |
        clean$Rating %in% 1:5),
  
  all(clean$Status %in%
        c("Cancelled", "Completed", "Returned", "Pending", NA))
)

