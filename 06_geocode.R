## ---------------------------
##
## Script name: 06_geocode.R
##
## Purpose of script: To geocode the cleaned address set for mapping the geographic distribution.
##
## Author: Cal Chengqi Fang
##
## Date Created: 2024-01-24
##
## Copyright (c) Cal Chengqi Fang, 2023
## Email: cal.cf@uchicago.edu
##
## ---------------------------
##
## Notes:
##   This is intended for the use of geocoding MMC-contracted locations for the medical credit card 
##   project.
##
##   In order to run this script, you need to put a Google map API key at line 59. You can obtain 
##   such an API following the instruction here: https://blog.hubspot.com/website/google-maps-api
##   One thing to be noted here is running this whole script would cost around $1000 Google map api 
##   use. Each new Google account comes with $300 credit. Each Google account can have $200 free 
##   use per month. That means, you need to have at least 2 Google account and API keys to avoid 
##   any actual bill incurred.
##
## ---------------------------

## set working directory for Mac and PC
setwd("/Users/atchoo/Documents/GitHub/MedicalCreditCard")  # Cal's working directory (mac)
# setwd("C:/Users/")     # Cal's working directory (PC)

## ---------------------------

rm(list=ls())
options(scipen=6, digits=4)         # I prefer to view outputs in non-scientific notation
options(nwarnings = 10000)          # I want to see all the warning message for the API step
memory.limit(30000000)                  # this is needed on some PCs to increase memory allowance, but has no impact on macs.

## ---------------------------

## load up the packages we will need:  (uncomment as required)

require(tidyverse)
require(ggmap)
require(xml2)
require(sf)
require(rnaturalearth)    # Needed for the US map sf object
require(maps)             # Needed for the states map sf object
require(furrr)            # Needed for parallel requesting
require(tidygeocoder)     # Needed for geocoding - some function in ggmap can do this too but this one works better with parallel requesting

## ---------------------------
# STEP 1
# Load the cleaned data
load("results/cleaned.Rdata")

# Set up Google Map API
Sys.setenv("GOOGLEGEOCODE_API_KEY" = "YOURGOOGLEMAPAPIKEYGOESHERE")

# Create a longer address to avoid "not uniquely geocoded" errors
mcc_clean <- mcc_clean %>% 
  mutate(addressLong = paste0(address, ", ", 
                              city, ", ",
                              state, " ", zipcode, ", ",
                              "USA"))

# Drop the duplicate offices kept for specialty analysis
mcc_clean <- mcc_clean %>% 
  distinct(name, addressLong, .keep_all = TRUE)

# Split the locations to four parts so we can make sure not exceeding Google API free use limit - cuz I am poor
split <- mcc_clean %>% 
  group_by((row_number()-1) %/% (n()/4)) %>%
  nest %>% pull(data)

names(split) <- c("split1", "split2", "split3", "split4")
list2env(split, envir=globalenv())


# STEP 2
# Write a function to use Google Map API to obtain coordinates for each split
geocode_split <- function(split, warningfile="warning.txt"){
  address_list <- split %>% 
    select(addressLong) %>%
    as.list()
  
  # Set up parallel requesting
  plan(strategy="multisession", workers=availableCores() - 8)
  split_geocode <- future_map(.x=address_list, 
                               ~ geo(address=.x, method="google", lat="lat", lon="lon", batch_limit=NULL)) %>% 
    bind_rows()
  
  # Save all warning message
  error <- names(warnings())
  out <- file(paste0("results/", warningfile))
  writeLines(error, out)
  close(out)
  
  lon <- split_geocode$lon
  lat <- split_geocode$lat
  split_geocoded <- cbind(split, lon, lat)
  
  return(split_geocoded)
}

# Geocode each split and save the warnings and result in between
split1_geocoded <- geocode_split(split1, "warning1.txt")
# save(split1_geocoded, 
#      file="results/geocoded.Rdata")
split2_geocoded <- geocode_split(split2, "warning2.txt")
# save(split1_geocoded, split2_geocoded, 
#      file="results/geocoded.Rdata")
split3_geocoded <- geocode_split(split3, "warning3.txt")
# save(split1_geocoded, split2_geocoded, split3_geocoded, 
#      file="results/geocoded.Rdata")
split4_geocoded <- geocode_split(split4, "warning4.txt")
# save(split1_geocoded, split2_geocoded, split3_geocoded, split4_geocoded,
#      file="results/geocoded.Rdata")
                # There were some "not uniquely geocoded" errors. Google Map replaced these address
                # with some close address in their data. I saved the warning messages and checked manually
                # to see whether the address they used were wrong. No issue was found.

# Combine all four splits back
mcc_geocoded_temp <- rbind(split1_geocoded, split2_geocoded, split3_geocoded, split4_geocoded)


# STEP 3
# Take out all rows that were returned NA geocodes and regeocode them
mcc_NA <- mcc_geocoded_temp[is.na(mcc_geocoded_temp$lon), ] %>% 
  select(-lon, -lat)

mcc_NA_regeocoded <- geocode_split(mcc_NA, "warning5.txt")

# There is one Po Box address that could not be geocoded we have to do it manually
print(mcc_NA_regeocoded[is.na(mcc_NA_regeocoded$lon), ])
POBOX402 <- geo(address="James H Brower DDS, York, NE 68467, USA", 
                method="google", lat="lat", lon="lon", batch_limit=NULL)

mcc_NA_regeocoded[is.na(mcc_NA_regeocoded$lon), "lon"] <- POBOX402$lon
mcc_NA_regeocoded[is.na(mcc_NA_regeocoded$lat), "lat"] <- POBOX402$lat

# Create the final all-geocoded data
mcc_geocoded <- mcc_geocoded_temp[!is.na(mcc_geocoded_temp$lon), ] %>% 
  rbind(mcc_NA_regeocoded)


# STEP 4
# Save the data
save(mcc_geocoded, 
     file="results/geocoded.Rdata")

