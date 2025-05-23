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
##      some partners that provided multiple services on their website. I will split such specialty 
##      information for later analysis. For instance, if a practice' specialty were "OB/GYN, 
##      Pediatrician", it would be split to two rows with specialty being "OB/GYN" and "Pediatrician" 
##      and everything else the same.
##   3. Some specialty info were too detailed and not very important for this project so we are gonna 
##      regroup them. This process would create some duplicates. I also dropped these duplicates.
##   4. There are some practices located in US territories. These are not so relevant to this project 
##      so I dropped them.
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


# ----------------------------------------------- STEP 1 -----------------------------------------------
# Load the data and drop duplicates created from scrapping process
carecredit <- read_csv("data/carecredit.csv") %>% 
  distinct() %>% 
  rename(address=address1,
         specialty=specialties) %>% 
  select(-location) 

alphaeon <- read_csv("data/alphaeon.csv") %>% 
  distinct() %>% 
  rename(address=address1,
         specialty=specialties) %>% 
  select(-location)

wellsfargoHA <- read_csv("data/wellsfargoHA.csv") %>% 
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

wellsfargoHA <- wellsfargoHA %>% 
  mutate(address = str_to_title(address),
         city = str_to_title(city)) %>% 
  distinct(address, phone, .keep_all=TRUE) 


# ----------------------------------------------- STEP 2 -----------------------------------------------
# Drop all animal-related practices in carecredit and alphaeon
carecredit <- carecredit %>% 
  filter(!grepl("Pet|Vet|Animal|Equine", specialty) & 
           !grepl("\\bPet\\b|\\bVet\\b|Veterinary|Veterinarian|Animal|Equine", name))

wellsfargoHA <- wellsfargoHA %>% 
  filter(!grepl("Veterinary", specialty))


# ----------------------------------------------- STEP 3 -----------------------------------------------
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


# ----------------------------------------------- STEP 3 -----------------------------------------------
# Regroup the specialty
# Rename some specialty for consistency
carecredit$specialty[carecredit$specialty=="Outpatient Surgery Center"] <- "Surgery Centers"
carecredit$specialty[carecredit$specialty=="Dermatologist"] <- "Dermatology"
carecredit$specialty[carecredit$specialty=="OB/GYN"] <- "Obstetrics & Gynecology"
carecredit$specialty[carecredit$specialty=="Urgent Care / Walk-in Clinics"] <- "Urgent Care/Walk-in Clinics"

# Build a clean specialty list
raw_list <- unique(c(carecredit$specialty, alphaeon$specialty, wellsfargoHA$specialty))

dental <- grep("Den|dontist|dontics|Oral", raw_list, value=TRUE)
vision <- grep("Eye|Ophth|Cataract|LASIK|Retina|Optometrist|Vision", raw_list, value=TRUE)
audio <- grep("Hearing|Audio", raw_list, value=TRUE)
cosmetic <- grep("Hair|Cosmetic|Plastic|Aesthetics|Weight", raw_list, value=TRUE)
physical <- grep("Phy", raw_list, value=TRUE)
other <- grep("Cord|Other|Lice", raw_list, value=TRUE) # Here the other vector mistakenly includes "other cosmetic" but 
                                                       # these would be kept through the cosmetic group anyway
unrelated <- grep("Medspa|Spa|Beauty|Supplements|Mattresses|Funeral", raw_list, value=TRUE)
equipment <- grep("Equipment|Wheelchair|Prosthetics|Monitors", raw_list, value=TRUE)
pharm <- grep("Pharm", raw_list, value=TRUE)
radio <- grep("Radiology", raw_list, value=TRUE)
family <- grep("General Practitioner", raw_list, value=TRUE)
vascular <- grep("Vascular", raw_list, value=TRUE)
sleep <- grep("Sleep", raw_list, value=TRUE)
surgery <- grep("Surgery Center", raw_list, value=TRUE)

rest <- raw_list %>% 
  setdiff(c(dental, vision, audio, cosmetic, physical, pharm, radio, family, vascular, sleep, surgery,
            other, unrelated, equipment))

regroup <- bind_rows(
  data.frame(specialty = dental, specialty_re = "Dentistry"),
  data.frame(specialty = vision, specialty_re = "Vision Medicine"),
  data.frame(specialty = audio, specialty_re = "Audiology"),
  data.frame(specialty = cosmetic, specialty_re = "Cosmetic Medicine"),
  data.frame(specialty = physical, specialty_re = "Physical Medicine & Rehabilitation"),
  data.frame(specialty = other, specialty_re = "Unknown/Others"),
  data.frame(specialty = unrelated, specialty_re = "Unrelated"),
  data.frame(specialty = equipment, specialty_re = "Medical Equipment"),
  data.frame(specialty = pharm, specialty_re = "Pharmacy"),
  data.frame(specialty = radio, specialty_re = "Imaging & Radiology"),
  data.frame(specialty = family, specialty_re = "Family & General Practitice"),
  data.frame(specialty = vascular, specialty_re = "Vascular Surgery"),
  data.frame(specialty = sleep, specialty_re = "Sleep Medicine"),
  data.frame(specialty = surgery, specialty_re = "Outpatient Surgery"),
  data.frame(specialty = rest, specialty_re = rest)
)

# Regroup the original data and drop business that should not be considered as medical practices
carecredit_clean <- carecredit %>% 
  merge(regroup, all.x=TRUE) %>% 
  distinct() %>% 
  filter(!specialty_re %in% c("Unrelated", "Medical Equipment", "Unknown/Others"))

alphaeon_clean <- alphaeon %>% 
  merge(regroup, all.x=TRUE) %>% 
  distinct() %>% 
  filter(!specialty_re %in% c("Unrelated", "Medical Equipment", "Unknown/Others"))

wellsfargoHA_clean <- wellsfargoHA %>% 
  merge(regroup, all.x=TRUE) %>% 
  distinct() %>% 
  filter(!specialty_re %in% c("Unrelated", "Medical Equipment", "Unknown/Others"))


# ----------------------------------------------- STEP 4 -----------------------------------------------
# Bind the three dataframes
mcc_clean <- bind_rows(list(carecredit=carecredit_clean, 
                            alphaeon=alphaeon_clean, 
                            wellsfargoHA=wellsfargoHA_clean), .id = 'credit') 

# Drop the duplicates caused by regrouping the specialty
mcc_clean <- mcc_clean %>% 
  select(-specialty) %>% 
  distinct()

# Only keep the practices in 50 states and DC
mcc_clean <- mcc_clean %>% 
  filter(state %in% c(state.abb, "DC"))


# ----------------------------------------------- STEP 5 -----------------------------------------------
# Save the data
save(mcc_clean, 
     file="data/interm/cleaned.Rdata")

