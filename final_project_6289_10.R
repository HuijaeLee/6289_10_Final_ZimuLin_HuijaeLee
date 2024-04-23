# STAT 6289-10 Final Project Zimu Lin / Huijae Lee

r = getOption("repos")
r["CRAN"] = "http://cran.us.r-project.org"
options(repos = r)

# Import packages for shiny
install.packages("shiny")
install.packages("ggplot2")
install.packages("dplyr")
install.packages("plotly")  # For interactive pie charts
install.packages("shinydashboard")
install.packages("rsconnect")
# set max bundle size to 3GB to publish files on shiny.
options(rsconnect.max.bundle.size=3145728000)

library(shiny)
library(plotly)
library(ggplot2)
library(dplyr)
library(shinydashboard)
library(rsconnect)

ui <- dashboardPage(
  dashboardHeader(title = "Soccer Data Visualization"),
  dashboardSidebar(
    selectInput("xaxis", "Select X-axis Variable:",
                choices = c("player_id","goals", "yellow_cards", "red_cards",
                            "home_club_goals", "away_club_goals", "height_in_cm"),
                selected = "player_id"),
    selectInput("yaxis", "Select Y-axis Variable:",
                choices = c("goals", "yellow_cards", "red_cards",
                            "home_club_goals", "away_club_goals", "height_in_cm"),
                selected = "goals"),
    selectInput("size", "Select Bubble Size Variable:",
                choices = c("player_id","goals","yellow_cards", "red_cards",
                            "home_club_goals", "away_club_goals", "height_in_cm"),
                selected = "player_id"),
    sliderInput("sizeRange", "Bubble Size Range:", min = 1, max = 20, value = c(5, 15))
  ),
  dashboardBody(
    plotlyOutput("scatterPlot")
  )
)

server <- function(input, output) {
  # Load the soccer data
  soccerData <- read.csv("soccer2.csv")
  
  output$scatterPlot <- renderPlotly({
    validData <- soccerData %>%
      mutate(across(c(input$xaxis, input$yaxis, input$size), as.numeric)) %>%
      filter(!is.na(.[[input$xaxis]]), !is.na(.[[input$yaxis]]), !is.na(.[[input$size]]))
    
    plot_ly(validData, x = ~get(input$xaxis), y = ~get(input$yaxis),
            size = ~get(input$size), text = ~paste(input$xaxis, ": ", get(input$xaxis),
                                                   "<br>", input$yaxis, ": ", get(input$yaxis),
                                                   "<br>Size: ", get(input$size)),
            marker = list(sizemode = "diameter", size = ~get(input$size), 
                          sizeref = max(validData[[input$size]])/input$sizeRange[2],
                          sizemin = input$sizeRange[1]), type = "scatter", mode = "markers",
            hoverinfo = "text") %>%
      layout(title = paste("Interactive Scatter Plot: ", input$yaxis, " vs ", input$xaxis),
             xaxis = list(title = input$xaxis),
             yaxis = list(title = input$yaxis))
  })
}

# Run the application
shinyApp(ui, server)
