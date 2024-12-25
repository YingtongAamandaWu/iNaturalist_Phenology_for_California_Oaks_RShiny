# Title: Rshiny App examoning the phenology data for California Oaks
This is an interactive tool for visualizing and analyzing the temporal trends in flowering and fruiting phenology of major oak species in Pacific North West, U.S.

# Getting Started
## Prerequisites
Ensure you have the following installed:
R
RStudio (optional but recommended)
Required R packages (see below):
library(shiny)
library(plotly)
library(rinat)
library(stringr)
library(dplyr)
library(lubridate)
library(timetk)
library(leaflet)
library(leaflet.extras)
library(sf)
library(ggplot2)

## App Structure
project/

├── app.R          # Main Shiny app file

├── README.md      # Documentation file

├── Rshiny_web_deployment.R  # R script for deploying the RShiny app to Rshiny.io web server

# License
This project is licensed under the MIT License.
