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
##   2. CareCredit and Comenity's Alphaeon card both listed very detailed specialties information for 
##      some partners that provided multiple services on their website. I will split such specialties information
##      for later analysis. For instance, if a practice' specialties were "OB/GYN, Pediatrician", it would be split
##      to two rows with specialties being "OB/GYN" and "Pediatrician" and everything else the same.
##   3. Some specialties info were too detailed and not very important for this project so we are gonna regroup them.
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
# Load the data
carecredit <- read_csv("results/carecredit.csv") %>% 
  distinct() %>% 
  rename(address=address1)
alphaeon <- read_csv("results/alphaeon.csv") %>% 
  distinct() %>% 
  rename(address=address1)
wellsfargo <- read_csv("results/wellsfargo.csv") %>% 
  distinct() %>% 
  rename(address=address1)


# STEP 2 
# Drop all animal-related practices in carecredit and alphaeon
carecredit <- carecredit %>% 
  filter(!grepl("Pet|Vet|Animal|Equine", specialties) & 
           !grepl("\\bPet\\b|\\bVet\\b|Veterinary|Veterinarian|Animal|Equine", name))

wellsfargo <- wellsfargo %>% 
  filter(!grepl("Veterinary", specialties))


# STEP 3
# Split long specialties descriptions in carecredit and alphaeon to multiple rows
carecredit <- carecredit %>% 
  separate_longer_delim(cols = specialties, delim = ", ") %>% 
  mutate(specialties = ifelse(specialties %in% c("Ear", "Nose & Throat"), 
                              "Ear, Nose & Throat", specialties)) %>% 
  distinct() %>% 
  drop_na(specialties)

alphaeon <- alphaeon %>%
  mutate(specialties = str_replace_all(specialties, "\\s{2,}|\\n", "")) %>% 
  separate_longer_delim(cols = specialties, delim = ",") %>% 
  distinct() %>% 
  drop_na(specialties)


# STEP 4 Regroup the specialties
# Rename some specialties for consistency
carecredit$specialties[carecredit$specialties=="Outpatient Surgery Center"] <- "Surgery Centers"
carecredit$specialties[carecredit$specialties=="Dermatologist"] <- "Dermatology"

# Build a clean specialties list
raw_list <- unique(c(carecredit$specialties, alphaeon$specialties, wellsfargo$specialties))

unrelated <- grep("Medspa|Spa|Beauty|Supplements|Mattresses|Funeral", raw_list, value=TRUE)
equipment <- grep("Equipment|Wheelchair|Prosthetics|Monitors", raw_list, value=TRUE)
altmed <- grep("Pharm|Therapist|Phys|Acupu|Chiro", raw_list, value=TRUE)
dental <- grep("Den|dontist|dontics|Oral", raw_list, value=TRUE)
vision <- grep("Eye|Ophth|Cataract|LASIK|Retina|Optometrist|Vision", raw_list, value=TRUE)
audio <- grep("Hearing|Audio", raw_list, value=TRUE)
cosmetic <- grep("Hair|Cosmetic|Plastic|Aesthetics|Weight", raw_list, value=TRUE)
other <- grep("Cord|Other|Lice", raw_list, value=TRUE)

rest <- raw_list %>% 
  setdiff(c(unrelated, equipment, altmed, dental, vision, audio, cosmetic, other))

regroup <- bind_rows(
  data.frame(specialties = unrelated, specialties_re = "Unrelated"),
  data.frame(specialties = equipment, specialties_re = "Medical Equipment"),
  data.frame(specialties = altmed, specialties_re = "Supplmental/Alternative Medicine"),
  data.frame(specialties = dental, specialties_re = "Dentistry"),
  data.frame(specialties = vision, specialties_re = "Vision Medicine"),
  data.frame(specialties = cosmetic, specialties_re = "Cosmetic Medicine"),
  data.frame(specialties = audio, specialties_re = "Audiology"),
  data.frame(specialties = other, specialties_re = "Unknown/Others"),
  data.frame(specialties = rest, specialties_re = rest)
)

# Regroup and combine
carecredit_clean <- carecredit %>% 
  merge(regroup, all.x=TRUE) %>% 
  distinct() %>% 
  filter(!specialties_re %in% c("Unrelated", "Medical Equipment", "Unknown/Others"))

alphaeon_clean <- alphaeon %>% 
  merge(regroup, all.x=TRUE) %>% 
  distinct() %>% 
  filter(!specialties_re %in% c("Unrelated", "Medical Equipment", "Unknown/Others"))

wellsfargo_clean <- wellsfargo %>% 
  merge(regroup, all.x=TRUE) %>% 
  distinct() %>% 
  filter(!specialties_re %in% c("Unrelated", "Medical Equipment", "Unknown/Others"))


# STEP 5 
mcc_clean <- bind_rows(list(carecredit=carecredit_clean, 
                            alphaeon=alphaeon_clean, 
                            wellsfargo=wellsfargo_clean), .id = 'credit')

save(carecredit_clean, alphaeon_clean, wellsfargo_clean,
     mcc_clean, 
     file="results/cleaned.Rdata")

