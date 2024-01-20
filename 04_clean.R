## ---------------------------
##
## Script name: 04_clean.R
##
## Purpose of script: To clean the raw data scraped from the three agencies' websites.
##
## Author: Cal Chengqi Fang
##
## Date Created: 2024-01-05
##
## Copyright (c) Cal Chengqi Fang, 2023
## Email: cal.cf@uchicago.edu
##
## ---------------------------
##
## Notes:
##   1. CareCredit and Comenity's Alphaeon card both listed veterinary partners on their website
##      which is not of interest to us and needs to be dropped.
##   2. CareCredit and Comenity's Alphaeon card both listed very detailed specialty information for 
##      some partners that provided multiple services on their website. I will split such specialty information
##      for later analysis. For instance, if a practice' specialty were "OB/GYN, Pediatrician", it would be split
##      to two rows with specialty being "OB/GYN" and "Pediatrician" and everything else the same.
##   3. Some specialty info were too detailed and not very important for this project so we are gonna regroup them.
##
## ---------------------------

## set working directory for Mac and PC
setwd("/Users/atchoo/Documents/GitHub/MedicalCreditCard")  # Cal's working directory (mac)
# setwd("C:/Users/")     # Cal's working directory (PC)

## ---------------------------

rm(list=ls())
options(scipen=6, digits=4)         # I prefer to view outputs in non-scientific notation
memory.limit(30000000)              # this is needed on some PCs to increase memory allowance, but has no impact on macs.

## ---------------------------

## load up the packages we will need:  (uncomment as required)

require(tidyverse)

## ---------------------------
# STEP 1 
# Load the data and drop duplicates created from scrapping process
carecredit <- read_csv("results/carecredit.csv") %>% 
  distinct() %>% 
  rename(address=address1,
         specialty=specialties) %>% 
  select(-location) 

alphaeon <- read_csv("results/alphaeon.csv") %>% 
  distinct() %>% 
  rename(address=address1,
         specialty=specialties) %>% 
  select(-location)

wellsfargo <- read_csv("results/wellsfargo.csv") %>% 
  distinct() %>% 
  rename(address=address1,
         specialty=specialties) %>% 
  select(-location)

# Drop more duplicates in the three card locator database
carecredit <- carecredit %>% 
  mutate(address = str_to_title(address),
         city = str_to_title(city)) %>% 
  distinct(address, phone, .keep_all=TRUE) 

alphaeon <- alphaeon %>% 
  mutate(address = str_to_title(address),
         city = str_to_title(city)) %>% 
  distinct(address, phone, .keep_all=TRUE) 

wellsfargo <- wellsfargo %>% 
  mutate(address = str_to_title(address),
         city = str_to_title(city)) %>% 
  distinct(address, phone, .keep_all=TRUE) 


# STEP 2 
# Drop all animal-related practices in carecredit and alphaeon
carecredit <- carecredit %>% 
  filter(!grepl("Pet|Vet|Animal|Equine", specialty) & 
           !grepl("\\bPet\\b|\\bVet\\b|Veterinary|Veterinarian|Animal|Equine", name))

wellsfargo <- wellsfargo %>% 
  filter(!grepl("Veterinary", specialty))


# STEP 3
# Split long specialty descriptions in carecredit and alphaeon to multiple rows
carecredit <- carecredit %>% 
  separate_longer_delim(cols = specialty, delim = ", ") %>% 
  mutate(specialty = ifelse(specialty %in% c("Ear", "Nose & Throat"), 
                              "Ear, Nose & Throat", specialty)) %>% 
  distinct() %>% 
  drop_na(specialty)

alphaeon <- alphaeon %>%
  mutate(specialty = str_replace_all(specialty, "\\s{2,}|\\n", "")) %>% 
  separate_longer_delim(cols = specialty, delim = ",") %>% 
  distinct() %>% 
  drop_na(specialty)


# STEP 4 Regroup the specialty
# Rename some specialty for consistency
carecredit$specialty[carecredit$specialty=="Outpatient Surgery Center"] <- "Surgery Centers"
carecredit$specialty[carecredit$specialty=="Dermatologist"] <- "Dermatology"
carecredit$specialty[carecredit$specialty=="OB/GYN"] <- "Obstetrics & gynecology"

# Build a clean specialty list
raw_list <- unique(c(carecredit$specialty, alphaeon$specialty, wellsfargo$specialty))

dental <- grep("Den|dontist|dontics|Oral", raw_list, value=TRUE)
vision <- grep("Eye|Ophth|Cataract|LASIK|Retina|Optometrist|Vision", raw_list, value=TRUE)
audio <- grep("Hearing|Audio", raw_list, value=TRUE)
cosmetic <- grep("Hair|Cosmetic|Plastic|Aesthetics|Weight", raw_list, value=TRUE)
physical <- grep("Phy", raw_list, value=TRUE)
other <- grep("Cord|Other|Lice", raw_list, value=TRUE)
unrelated <- grep("Medspa|Spa|Beauty|Supplements|Mattresses|Funeral", raw_list, value=TRUE)
equipment <- grep("Equipment|Wheelchair|Prosthetics|Monitors", raw_list, value=TRUE)
marginmed <- grep("Pharm|Speech|Acupu|Chiro|Home", raw_list, value=TRUE)

rest <- raw_list %>% 
  setdiff(c(dental, vision, audio, cosmetic, physical, other, unrelated, equipment, marginmed))

regroup <- bind_rows(
  data.frame(specialty = dental, specialty_re = "Dentistry"),
  data.frame(specialty = vision, specialty_re = "Vision Medicine"),
  data.frame(specialty = audio, specialty_re = "Audiology"),
  data.frame(specialty = cosmetic, specialty_re = "Cosmetic Medicine"),
  data.frame(specialty = physical, specialty_re = "Physical Medicine & Rehabilitation"),
  data.frame(specialty = other, specialty_re = "Unknown/Others"),
  data.frame(specialty = unrelated, specialty_re = "Unrelated"),
  data.frame(specialty = equipment, specialty_re = "Medical Equipment"),
  data.frame(specialty = marginmed, specialty_re = "Supplmental/Alternative Medicine"),
  data.frame(specialty = rest, specialty_re = rest)
)

# Regroup and combine
carecredit_clean <- carecredit %>% 
  merge(regroup, all.x=TRUE) %>% 
  distinct() %>% 
  filter(!specialty_re %in% c("Unrelated", "Medical Equipment", "Unknown/Others"))

alphaeon_clean <- alphaeon %>% 
  merge(regroup, all.x=TRUE) %>% 
  distinct() %>% 
  filter(!specialty_re %in% c("Unrelated", "Medical Equipment", "Unknown/Others"))

wellsfargo_clean <- wellsfargo %>% 
  merge(regroup, all.x=TRUE) %>% 
  distinct() %>% 
  filter(!specialty_re %in% c("Unrelated", "Medical Equipment", "Unknown/Others"))


# STEP 5 
# Bind the three dataframes
mcc_clean <- bind_rows(list(carecredit=carecredit_clean, 
                            alphaeon=alphaeon_clean, 
                            wellsfargo=wellsfargo_clean), .id = 'credit') 

# Drop the duplicates caused by regrouping the specialty
mcc_clean <- mcc_clean %>% 
  select(-specialty) %>% 
  distinct()

# Duplicate suspect
test <- mcc_clean %>% 
  group_by(phone) %>% 
  summarize(count = n()) %>% 
  filter(count > 1)


# STEP 6
# Save the data
save(carecredit_clean, alphaeon_clean, wellsfargo_clean,
     mcc_clean, 
     file="results/cleaned.Rdata")

