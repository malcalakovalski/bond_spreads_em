# Goal:
# - I have bond spread data for 11 countries downloaded from Bloomberg each in their own xlsx file
# - I want to combine these files into one

# Setup
librarian::shelf(tidyverse, # You know
                 janitor, # You know
                 purrr, # For loops but using functional programming
                 readxl, # Import xlsx files
                 openxlsx, # Another package for importing/exporting xlsx files
                 lubridate, # Handling dates
                 fs # File management (terminal functions but nice in R)
                 )

# List file paths in data folder
# Conveniently this names the elements of the list as the file names too. So you get a named list which is nice
file.list <- dir_ls('data')
file.list

# Import data with a custom function
# The date variable in all these files gets read in as <dttm>, the ordering is from last to beginning (So first row is 2022 and last one is 1995 which sucks), and there's a column i don't care about (PX_MID)

import_bond_data <- function(file){
  read_xlsx(file) %>%
    clean_names() %>%
    mutate(date = as_date(date)) %>%
    arrange(date) %>%
    select(-px_mid)
}

# Check that our function works as expected
import_bond_data('data/argentina.xlsx')

# Note: I could do this before combining data or after. Sometimes one is easier than the other but in this case it's the same. I'll do it first to demonstrate how to incorporate custom functions into this framework.

# Iteration time
# purrr::map_df is a life saver. It iterates (maps) over a list in the first argument using the function in the second
# The id argument lets us create a column containing an identifier for each list element. In our case this creates a column with the names of the file from which the data came from for each row.
# I have a country column already, but with some string manipulation we could transform the id column to a Country one easily.
# I'm just including it to show you but in this case I wouldn't.

bonds <- map_dfr(.x = file.list, .f = import_bond_data, .id = "id")

# Exporting
# Now I'm just going to prep the data in the format I want to send to my boss

bonds %>%
  select(date, country, security, px_last) %>%
  openxlsx::write.xlsx('bond_spreads_em.xlsx')

# A simple plot now!
ggplot(bonds, aes(x = date, y = px_last)) +
  geom_line() +
  facet_wrap(~ country)
