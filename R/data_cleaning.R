rm(list = ls())

library(dplyr)
library(tidyr)
library(janitor)
library(readxl)
library(readr)
library(tidylog)
library(stringr)

# import dataset ----------
dirty <- read_excel("data/Data Cleaning Dataset.xlsx", 
                    sheet = "Raw Orders")

instruction <- read_excel("data/Data Cleaning Dataset.xlsx", 
                          sheet = "README")

clean <- dirty |> 
  janitor::remove_empty("rows") |> 
  mutate(Customer_Name = str_to_title(case_when(
    !is.na(`Customer Name`) ~ `Customer Name`,
    !str_detect(Email, "@") ~ str_replace(Email, "\\."," "),
    TRUE ~ str_replace_all(str_extract(Email, "^[^@]+"), "\\.", " ")
  ))) |> 
  rename(email_old = Email) |> 
  mutate(Email = case_when(
    str_detect(email_old, "@") ~ str_extract(email_old, "^[^@]+")
  )) |> 
  mutate(Email = paste0(str_to_lower(Email), "@example.com")) |> 
  rename(phone_old = Phone) |> 
  mutate(Phone = case_when(
    str_detect(phone_old, "[()+-]") ~ str_remove(str_remove_all(phone_old, "[()+-]")," "),
    TRUE ~ phone_old
  )) |> 
  mutate(Phone = case_when(
    str_length(Phone) == 12 ~ paste0("0",str_sub(Phone, 4,12)),
    str_length(Phone) == 10 ~ Phone
  )) |> 
  rename(city_old = City) |> 
  mutate(City = str_to_title(city_old)) |> 
  mutate(City = case_when(
    City == "Kissumu" ~ "Kisumu",
    City == "Mombassa" ~ "Mombasa",
    City == "Niarobi" ~ "Nairobi",
    TRUE ~ City
  )) |> 
  rename(product_old = Product) |> 
  mutate(Product = str_squish(str_to_title(product_old))) |> 
  mutate(Product = case_when(
    str_detect(Product, "Usb") ~ "USB Flash Drive",
    # Product == "Usb Flash Drive" ~ "USB Flash Drive",
    # Product == "Usb Drive" ~ "USB Flash Drive",
    # Product == "Usb Flash Drive" ~ "USB Flash Drive",
    Product == "External Hdd" ~ "External Hard Drive",
    Product == "Lap Top" ~ "Laptop",
    Product == "Head Phones" ~ "Headphones",
    Product == "Desktop Pc" ~ "Desktop PC",
    TRUE ~ Product
  )) |> 
  rename(category_old = Category) |> 
  mutate(Category = case_when(
    str_detect(Product, "Desktop|Laptop|Tablet") ~ "Computers",
    str_detect(Product, "Monitor") ~ "Electronics",
    NA ~ NA_character_,
    str_detect(Product, "Printer") ~ "Office Equipment",
    TRUE ~ "Accessories"
  )) |> 
  mutate(Quantity = case_when(
    Quantity <= 0 | Quantity == 999 ~ NA_real_,
    TRUE ~ Quantity
  )) |> 
  rename(unit_price_old = `Unit Price`) |> 
  mutate(`Unit Price` = case_when(
    str_detect(unit_price_old, "\\$") ~ as.numeric(str_remove(unit_price_old, "\\$")) * 130,
    str_detect(unit_price_old, "KES") ~ as.numeric(parse_number(unit_price_old)),
    TRUE ~ as.numeric(unit_price_old)
  )) |> 
  rename(payment_method_old = `Payment Method`) |> 
  mutate(`Payment Method` = str_squish(str_to_title(payment_method_old))) |> 
  mutate(`Payment Method` = case_when(
    str_detect(`Payment Method`, "Cc|Credit Card") ~ "Credit Card",
    str_detect(`Payment Method`, "Mobile|pesa") ~ "M-Pesa",
    TRUE ~ `Payment Method`)
  ) |> 
  # rename(order_date_old = `Order Date`) |>
  # separate(order_date_old, into = c("d", "m", "y"), remove = FALSE) |> 
  # mutate(`Order Date` = case_when(
  #   d > 12 & m > 30 ~ str_c(y,m,d,sep = "-"),
  #   d > 30 & m > 12 ~ str_c(y,d,m,sep = "-"),
  #   d > 2000 & m > 12 ~ str_c(d,m,y,sep = "-"),
  #   d > 2000 & m > 30 ~ str_c(d,y,m,sep = "-"),
  # 
  #   TRUE ~ NA_character_
  # )) |> 
  rename(status_old = Status) |> 
  mutate(Status = case_when(
    str_detect(status_old, regex("cancel", ignore_case = TRUE)) ~ "Cancelled",
    str_detect(status_old, regex("complete", ignore_case = TRUE)) ~ "Completed",
    str_detect(status_old, regex("return", ignore_case = TRUE)) ~ "Returned",
    str_detect(status_old, regex("pending", ignore_case = TRUE)) ~ "Pending",
    
    TRUE ~ status_old
  )) |> 
  mutate(Rating = as.numeric(case_when(
    Rating == "N/A" ~ NA_character_,
    Rating == 'five' ~ "5",
    TRUE ~ Rating
  ))) |> 
  select(`Order ID`, Customer_Name, Email, Phone, City, Product, Category, Quantity, `Unit Price`, `Payment Method`, `Order Date`, Status, Rating)
  


clean |> select(status_old, Status) |> distinct(status_old, .keep_all = TRUE)


# writexl::write_xlsx(clean, "output/clean_dataset.xlsx")
