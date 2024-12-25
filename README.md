# Title: Rshiny App examining the phenology data for California Oaks
This interactive tool visualizes and analyzes the temporal trends in flowering and fruiting phenology of major oak (_Quercus_) species in the Pacific Northwest, U.S.
The RShiny App can be found via this link: [https://ytamandawu.shinyapps.io/20241223iNaturalistPhenologyloopQspeciesfruitingfloweringRShiny/](https://ytamandawu.shinyapps.io/20241223iNaturalistPhenologyloopQspeciesfruitingfloweringRShiny/) 
![image](https://github.com/user-attachments/assets/69180c11-7c93-4a51-874b-29e61df7cd8a)

# Getting Started
## Prerequisites
Ensure you have the following installed:
1. R
   
2. RStudio (optional but recommended)
   
3. Required R packages (see below):
   
library(shiny)

library(plotly)

library(rinat)

library(string)

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
