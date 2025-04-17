## ---------------------------
##
## Script name: 07_map.R
##
## Purpose of script: To draw a map for all 180,320 unique office locations.
##
## Author: Cal Chengqi Fang
##
## Date Created: 2024-03-06
##
## Copyright (c) Cal Chengqi Fang, 2023
## Email: cal.cf@uchicago.edu
##
## ---------------------------
##
## Notes:
##   
##
## ---------------------------

## set working directory for Mac and PC
setwd("/Users/atchoo/Documents/GitHub/MedicalCreditCard")  # Cal's working directory (mac)
# setwd("C:/Users/")     # Cal's working directory (PC)

## ---------------------------

rm(list=ls())
options(scipen=6, digits=4)         # I prefer to view outputs in non-scientific notation
memory.limit(30000000)                  # this is needed on some PCs to increase memory allowance, but has no impact on macs.

## ---------------------------

## load up the packages we will need:  (uncomment as required)

require(tidyverse)
require(data.table)
require(ggmap)
require(xml2)
require(ggplot2)
theme_set(theme_bw())     # Set up the ggplot2 style
require(sf)
require(rnaturalearth)    # Needed for the US map sf object
require(maps)             # Needed for the states map sf object

## ---------------------------


# ----------------------------------------------- STEP 1 -----------------------------------------------
# Read in the geocoded data
load("data/interm/geocoded.Rdata")

# Obtain the US sf object for shapefile use
US <- rnaturalearth::ne_countries(scale="medium", returnclass="sf") %>% 
  filter(sovereignt == "United States of America")

# Obtain the states sf object for shapefile use
states <- sf::st_as_sf(maps::map("state", plot=FALSE, fill=TRUE))

# Change the credit name for consistency
mcc_geocoded <- mcc_geocoded %>% 
  select(-addressLong) %>% 
  mutate(credit=case_when(credit == "carecredit" ~ "CareCredit credit card",
                          credit == "alphaeon" ~ "Alphaeon credit card",
                          credit == "wellsfargoHA" ~ "Wells Fargo Health Advantage card"))


# ----------------------------------------------- STEP 2 -----------------------------------------------
# Map the locations for the mainland graph
mainland <- ggplot(US) +
  geom_sf() +
  geom_sf(data=states, fill=NA) + 
  geom_point(data=filter(mcc_geocoded, credit == "CareCredit credit card"), 
             aes(x=lon, y=lat, color=credit), size=0.1) +   # Plot CareCredit credit card points first
  geom_point(data=filter(mcc_geocoded, credit %in% c("Alphaeon credit card", "Wells Fargo Health Advantage card")), 
             aes(x=lon, y=lat, color=credit), size=0.1) +   # Plot Alphaeon credit card and Wells Fargo Health Advantage card points second
  coord_sf(xlim=c(-130, -65), ylim=c(23, 51), expand=FALSE) +
  scale_color_manual(values=c("Alphaeon credit card"="#ba393a", 
                              "CareCredit credit card"="#00ac9d", 
                              "Wells Fargo Health Advantage card"="#ffcc02")) +
  labs(color="Medical Credit Card", shape="Medical Credit Card") +
  theme(axis.title.x=element_blank(), axis.title.y=element_blank(),
        axis.ticks=element_blank(), # Remove tick marks
        axis.ticks.length=unit(0, "mm"), # Set tick length to zero
        legend.position.inside=c(0.95, 0.05), # Adjust position
        legend.justification=c("right", "bottom"), # Align bottom right
        legend.key.size=unit(0.8, "cm"), # Increase size of legend key
        text=element_text(size=12, family="Arial")) + 
  guides(color=guide_legend(override.aes=list(size=2))) # Increase size of legend points

# Map the locations for Hawaii
HI <- ggplot(US) +
  geom_sf() +
  geom_sf(data=states, fill=NA) + 
  geom_point(data=filter(mcc_geocoded, credit == "CareCredit credit card"), 
             aes(x=lon, y=lat, color=credit), size=0.1) +   # Plot CareCredit credit card points first
  geom_point(data=filter(mcc_geocoded, credit %in% c("Alphaeon credit card", "Wells Fargo Health Advantage card")), 
             aes(x=lon, y=lat, color=credit), size=0.1) +   # Plot Alphaeon credit card and Wells Fargo Health Advantage card points second
  coord_sf(xlim=c(-160, -154.5), ylim=c(18.5, 23), expand=FALSE) +
  scale_color_manual(values=c("CareCredit credit card"="#00ac9d", 
                              "Alphaeon credit card"="#ba393a", 
                              "Wells Fargo Health Advantage card"="#ffcc02")) +
  theme(axis.title.x=element_blank(), axis.text.x=element_blank(), axis.ticks.x=element_blank(), 
        axis.title.y=element_blank(), axis.text.y=element_blank(), axis.ticks.y=element_blank(),
        legend.position="none")

# Map the locations for Alaska
AK <- ggplot(US) +
  geom_sf() +
  geom_sf(data=states, fill=NA) + 
  geom_point(data=filter(mcc_geocoded, credit == "CareCredit credit card"), 
             aes(x=lon, y=lat, color=credit), size=0.1) +   # Plot CareCredit credit card points first
  geom_point(data=filter(mcc_geocoded, credit %in% c("Alphaeon credit card", "Wells Fargo Health Advantage card")), 
             aes(x=lon, y=lat, color=credit), size=0.1) +   # Plot Alphaeon credit card and Wells Fargo Health Advantage card points second
  coord_sf(xlim=c(-180, -126), ylim=c(51, 72), expand=FALSE) +
  scale_color_manual(values=c("CareCredit credit card"="#00ac9d", 
                              "Alphaeon credit card"="#ba393a", 
                              "Wells Fargo Health Advantage card"="#ffcc02")) +
  theme(axis.title.x=element_blank(), axis.text.x=element_blank(), axis.ticks.x=element_blank(), 
        axis.title.y=element_blank(), axis.text.y=element_blank(), axis.ticks.y=element_blank(),
        legend.position="none")


# ----------------------------------------------- STEP 3 -----------------------------------------------
# Define the coordinates for overlaying AK and HI
overlay_coords <- data.frame(
  xmin=c(-130, -116),
  xmax=c(-115, -107),
  ymin=c(24, 24),
  ymax=c(32, 30)
)

# Overlay the maps of AK and HI onto the mainland map
mainland_with_overlay <- mainland +
  annotation_custom(
    grob=ggplotGrob(AK),
    xmin=overlay_coords$xmin[1],
    xmax=overlay_coords$xmax[1],
    ymin=overlay_coords$ymin[1],
    ymax=overlay_coords$ymax[1]
  ) +
  annotation_custom(
    grob=ggplotGrob(HI),
    xmin=overlay_coords$xmin[2],
    xmax=overlay_coords$xmax[2],
    ymin=overlay_coords$ymin[2],
    ymax=overlay_coords$ymax[2]
  )


# ----------------------------------------------- STEP 4 -----------------------------------------------
# Display the plot
print(mainland_with_overlay)

# Save the plot
ggsave("results/figure1.jpg", plot=mainland_with_overlay,
       width=12, height=7.5, dpi=300, units="in", scale=1, device="jpeg")

