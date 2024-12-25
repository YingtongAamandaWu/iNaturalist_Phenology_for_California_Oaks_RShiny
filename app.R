# Load libraries
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

# Define UI
# Define UI
ui <- fluidPage(
  # Title and description
  titlePanel("California Oak Species Phenology Analysis"),
  
  # Textbox with introduction and instructions
  div(
    style = "font-size: 14px; padding-bottom: 15px;",
    HTML("<p>This RShiny App uses real-time iNaturalist data (https://www.inaturalist.org/) to examine and visualize the trends of flowering and fruiting phenology of major Quercus (oak species) in the Pacific West Coast, primarily focusing on the dominant oak species in California. Please be patient after you click 'Update Data', since downloading the real-time data from the web server can take some time :) Thank you for using this app. 
         Feel free to contact the contributors of this app if you have any questions: Amanda Wu (ytwu@stanford.edu); David Henderson (dhenders013@gmail.com). You can also find more details from the GitHub repository: <a href='https://github.com/YingtongAamandaWu' target='_blank'>GitHub Repository</a>.</p>")
  ),
  
  sidebarLayout(
    sidebarPanel(
      selectInput("oak_species", "Select Oak Species:", 
                  choices = list(   "Quercus agrifolia (Coast Live Oak)" = 47850,
                                    "Quercus douglasii (Blue Oak)" = 49009,
                                    "Quercus lobata (Valley Oak)" = 49011, 
                                    "Quercus garryana (Oregon White Oak)" = 68632,
                                    "Quercus wislizeni (Interior live oak)" =51089,
                                    "Quercus chrysolepis (Canyon Live Oak)" =51092,
                                    "Quercus kelloggi (California black oak)" =49919,
                                    "Quercus engelmannii (Engelmann oak)" = 78804), 
                  selected = 47850),
      sliderInput("years", "Select Year Range:", 
                  min = 2007, max = 2024, 
                  value = c(2014, 2024), step = 1),
      actionButton("update", "Update Data")
    ),
    
    mainPanel(
      tabsetPanel(
        tabPanel("Heatmap of iNat observations", leafletOutput("heatmap")),
        tabPanel("Time Series of Flowering Phenology", 
                 plotlyOutput("time_series_flowering_plot"),
                 HTML("<div style='font-size: 12px; padding-top: 20px;'>
                        <strong>The figure above shows the relationship between the number of days for the phenology occurring, and year observed.</strong><br>
                        Kendall tau statistics was used to examine whether a significant trend was observed: P value indicates significant change, while Kendall tau indicates the direction of the trend (- means decreasing, + means increasing).<br>
                        The blue line is a smoothed curve that traces the yearly change in phenology. Small number right above each year indicate the samples size (akak the number of iNat observations).
                      </div>")
        ),
        tabPanel("Time Series of Fruiting Phenology", 
                 plotlyOutput("time_series_fruiting_plot"),
                 HTML("<div style='font-size: 12px; padding-top: 20px;'>
                        <strong>The figure above shows the relationship between the number of days for the phenology occurring, and year observed.</strong><br>
                        Kendall tau statistics was used to examine whether a significant trend was observed: P value indicates significant change, while Kendall tau indicates the direction of the trend (- means decreasing, + means increasing).<br>
                        The blue line is a smoothed curve that traces the yearly change in phenology. Small number right above each year indicate the samples size (akak the number of iNat observations).
                      </div>")
        )
      )
    )
  )
)


# Define server logic
server <- function(input, output, session) {
  
  # Reactive data loading and processing for flowering
  flowering_data <- eventReactive(input$update, {
    showNotification("Downloading data for flowering phenology, please wait...")
    
    # Download data for flowering
    species_data <- get_inat_obs(
      query = NULL, taxon_name = NULL, taxon_id = input$oak_species,
      quality = "research", geo = TRUE, 
      annotation = c(12, 13), # Plant phenology: Flowering
      maxresults = 10000
    )
    
    # Process data
    species_data <- species_data %>%
      filter(time_observed_at != "") %>%
      mutate(
        time_observed_at = as.POSIXct(time_observed_at, format = "%Y-%m-%d %H:%M:%S", tz = "UTC"),
        year_observed_at = as.numeric(str_extract(time_observed_at, "^.{4}")),
        days_since_year_start = as.numeric(difftime(
          time_observed_at, 
          as.POSIXct(paste0(format(time_observed_at, "%Y"), "-01-01"), tz = "UTC"),
          units = "days")) + 1
      ) %>%
      filter(year_observed_at %in% input$years[1]:input$years[2])
    
    species_data
  })
  
  # Reactive data loading and processing for fruiting
  fruiting_data <- eventReactive(input$update, {
    showNotification("Downloading data for fruiting phenology, please wait...")
    
    # Download data for fruiting
    species_data <- get_inat_obs(
      query = NULL, taxon_name = NULL, taxon_id = input$oak_species,
      quality = "research", geo = TRUE, 
      annotation = c(12, 14), # Plant phenology: Fruiting
      maxresults = 10000
    )
    
    # Process data
    species_data <- species_data %>%
      filter(time_observed_at != "") %>%
      mutate(
        time_observed_at = as.POSIXct(time_observed_at, format = "%Y-%m-%d %H:%M:%S", tz = "UTC"),
        year_observed_at = as.numeric(str_extract(time_observed_at, "^.{4}")),
        days_since_year_start = as.numeric(difftime(
          time_observed_at, 
          as.POSIXct(paste0(format(time_observed_at, "%Y"), "-01-01"), tz = "UTC"),
          units = "days")) + 1
      ) %>%
      filter(year_observed_at %in% input$years[1]:input$years[2])
    
    species_data
  })
  
  # Heatmap output
  output$heatmap <- renderLeaflet({
    data <- flowering_data()
    if (nrow(data) == 0) return(NULL)
    
    leaflet(data) %>%
      addProviderTiles("CartoDB.Positron") %>%
      addHeatmap(
        lng = ~longitude, lat = ~latitude, 
        blur = 5, max = 0.05, radius = 20
      )
  })
  
  # Time-series boxplot output for flowering phenology
  output$time_series_flowering_plot <- renderPlotly({
    data <- flowering_data()
    if (nrow(data) == 0) return(NULL)
    
    # Perform Kendall correlation
    cor_result <- cor.test(data$year_observed_at, data$days_since_year_start, method = 'kendall')
    tau <- round(as.numeric(cor_result$estimate), 4)
    p_val <- signif(cor_result$p.value, 4)
    
    # Count sample size per year
    sample_size <- data %>%
      group_by(year_observed_at) %>%
      summarise(count = n())
    
    # Plot with ggplot2 to add sample size under each tick
    plot <- data %>%
      ggplot(aes(x = year_observed_at, y = days_since_year_start)) +
      geom_boxplot() +
      geom_smooth(method = "loess", color = "blue", size = 1) +  # Add smoothed trend line (blue)
      labs(
        title = paste("Flowering Phenology | Tau:", tau, "| P-value:", p_val),
        x = "Year",
        y = "Number of days"
      ) +
      geom_text(data = sample_size, aes(x = year_observed_at, y = 0, label = count), 
                vjust = -1, size = 3) +  # Place sample size below x-ticks
      scale_x_continuous(breaks = seq(min(sample_size$year_observed_at), max(sample_size$year_observed_at), by = 1)) +  # Ensure one tick per year
      theme_minimal()
    
    # Convert ggplot to plotly for interactivity
    ggplotly(plot)
  })
  
  # Time-series boxplot output for fruiting phenology
  output$time_series_fruiting_plot <- renderPlotly({
    data <- fruiting_data()
    if (nrow(data) == 0) return(NULL)
    
    # Perform Kendall correlation
    cor_result <- cor.test(data$year_observed_at, data$days_since_year_start, method = 'kendall')
    tau <- round(as.numeric(cor_result$estimate), 4)
    p_val <- signif(cor_result$p.value, 4)
    
    # Count sample size per year
    sample_size <- data %>%
      group_by(year_observed_at) %>%
      summarise(count = n())
    
    # Plot with ggplot2 to add sample size under each tick
    plot <- data %>%
      ggplot(aes(x = year_observed_at, y = days_since_year_start)) +
      geom_boxplot() +
      geom_smooth(method = "loess", color = "blue", size = 1) +  # Add smoothed trend line (blue)
      labs(
        title = paste("Fruiting Phenology | Tau:", tau, "| P-value:", p_val),
        x = "Year",
        y = "Number of days"
      ) +
      geom_text(data = sample_size, aes(x = year_observed_at, y = 0, label = count), 
                vjust = -1, size = 3) +  # Place sample size below x-ticks
      scale_x_continuous(breaks = seq(min(sample_size$year_observed_at), max(sample_size$year_observed_at), by = 1)) +  # Ensure one tick per year
      theme_minimal()
    
    # Convert ggplot to plotly for interactivity
    ggplotly(plot)
  })
}

# Run the app
shinyApp(ui = ui, server = server)
