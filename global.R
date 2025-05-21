# Created: 2025-05-15
# Author: Alex Zajichek
# Project: Hospital Readmissions LLM Explorer (Shiny app to interact with readmission data in natural language)
# Description: Creates and loads global objects accessible to app

# Load packages
library(shiny)
library(tidyverse)
library(bslib)
library(datamods)
library(highcharter)
library(leaflet)
library(querychat)

options(tigris_use_cache=TRUE)

# Function to import dataset from CMS Provider Data Catalog (see https://github.com/zajichek/carecompare/blob/b1fa89382adfe77bd5f230f4162b03767ece10ea/R/FUNCTIONS.R#L99)
pdc_read <-
  function(
    datasetid = NULL,
    ...
  ) {
    
    # Check for input
    if(is.null(datasetid)) 
      stop("Please specify a dataset identifier.")
    
    # Make the url
    url <- paste0("https://data.cms.gov/provider-data/api/1/metastore/schemas/dataset/items/", datasetid, "?show-reference-ids=false")
    
    # Make the request, extract the content
    request <- httr::content(httr::GET(url))
    
    # Update the variable
    downloadurl <- request$distribution[[1]]$data$downloadURL
    
    # Import the dataset
    readr::read_csv(
      file = downloadurl,
      ...
    )
    
  }

## Import datasets

# Hospital information
hospitals <- pdc_read(datasetid = "xubh-q36u", guess_max = 10000) # https://data.cms.gov/provider-data/dataset/xubh-q36u

# HRRP outcomes
hrrp <- pdc_read(datasetid = "9n3s-kdb3", na = c("N/A", "", " ")) # https://data.cms.gov/provider-data/dataset/9n3s-kdb3

# Extract zip codes for WI
zips_wi <- tigris::zctas(year = 2010, state = "WI")

## Build mapping datasets

# Make zip code centroids
zips_wi_centroids <-
  zips_wi |>
  
  # Get the centroid
  sf::st_centroid() |>
  
  # Pluck the coordinates
  sf::st_coordinates() |>
  
  # Make a tibble
  as_tibble() |>
  
  # Add identifying column
  add_column(
    Zip = zips_wi$ZCTA5CE10
  ) |>
  
  # Rename columns
  rename(
    lon = X,
    lat = Y
  )

# Build map dataset
hospitals <-
  hospitals |>
  
  # Filter to Wisconsin hospitals
  filter(
    State == "WI",
    `Facility ID` %in% hrrp$`Facility ID`
  ) %>%
  
  # Keep a few pieces of information
  select(
    FacilityID = `Facility ID`,
    FacilityName = `Facility Name`,
    Address,
    City = `City/Town`,
    County = `County/Parish`,
    Zip = `ZIP Code`
  ) |>
  
  # Join to get the centroid for the hospital's zip code
  inner_join(
    y = zips_wi_centroids,
    by = "Zip"
  ) |>
  
  # Add random jitter to coordinates
  mutate(
    across(
      c(lat, lon),
      \(x) jitter(x, amount = 0.05)
    )
  )

# Make a clean measure lookup table
hrrp <-
  hrrp |>
  
  # Send down the rows
  pivot_longer(
    cols = matches("Readmission (Rate|Ratio)$"),
    names_to = "Measure",
    values_to = "Value"
  ) |>
  
  # Keep/format select columns
  transmute(
    FacilityID = `Facility ID`,
    DiagnosisCategory = 
      `Measure Name` |>
      
      # Remove prefix
      str_remove(pattern = "^READM-30-") |>
      
      # Remove suffix
      str_remove(pattern = "-HRRP$"),
    Measure =
      Measure |>
      
      # Remove suffix
      str_remove(pattern = "\\sReadmission (Rate|Ratio)$"),
    Value
  ) |>
  
  # Filter to hospitals of interest; no missing measures
  filter(
    !is.na(Value),
    FacilityID %in% hospitals$FacilityID
  ) |>
  
  # Send over the columns
  pivot_wider(
    names_from = Measure,
    values_from = Value
  )

# Make single table with all data
master_dat <- 
  hospitals |>
  
  # Join to get program results
  inner_join(
    y = hrrp,
    by = "FacilityID"
  )

### Build base map

# WI state outlines
state_outline <-
  maps::map(
    database = "state",
    regions = "wisconsin",
    fill = TRUE,
    plot = FALSE
  )

# County outlines
county_outlines <- 
  tigris::counties(cb = TRUE) %>%
  filter(
    STATE_NAME == "Wisconsin"
  )

# Base map
base_map <- 
  leaflet() %>%
  
  # Add geographic tiles
  addTiles() %>%
  
  # Add WI state outline
  addPolygons(
    data = state_outline,
    fillColor = "gray",
    stroke = FALSE
  ) |>
  
  # Add county outlines
  addPolygons(
    data = county_outlines,
    color = "black",
    fillColor = "white",
    weight = 1,
    opacity = .5,
    fillOpacity = .35,
    highlightOptions = 
      highlightOptions(
        color = "black",
        weight = 3,
        bringToFront = FALSE
      ),
    label = ~NAME
  )

# Set the pallette
pal <- 
  colorNumeric(
    palette = "RdYlGn",
    domain = -1*sort(unique(hrrp$Excess))
  )

# Configure the chat object
querychat_config <- 
  querychat_init(
    df = master_dat,
    tbl_name = "HospitalHRRP",
    create_chat_func = purrr::partial(ellmer::chat_gemini),
    greeting = "Ask me a question about the HRRP in Wisconsin",
    data_description = readLines("data_description.md")
  )
