# app.R

suppressPackageStartupMessages({
  library(shiny)
  library(ggplot2)
  library(dplyr)
  library(tidyr)
  library(here)
  library(glue)
})

here::i_am("shiny/app.R")      # pins project root to /app

# builds the widgets the user sees
ui <- fluidPage(
  titlePanel("Factor Beta Explorer"),
  sidebarLayout(
    sidebarPanel(
      selectInput("ticker",
                  "Choose ticker:",
                  choices = NULL, # fileld on startup
                  width = "100%")
    ),
    mainPanel(
      plotOutput("betaPlot", height = 400)
    )
  )
)

# holds logic
# inputs$: values coming from the UI
# output$: objects sent to the UI
server <- function(input, output, session) {

  observe({
    # search the output directory for all file names
    tickers <- basename(fs::dir_ls(here::here("output"),
                        type = "directory",
                        depth = 1))
    tickers <- sort(tickers) # pretty

    # update the selection box to be available ticker names
    updateSelectInput(session,
                      "ticker",
                      choices  = tickers,
                      selected = if (length(tickers)) tickers[1])
    print(glue::glue("Discovered tickers: {toString(tickers)}"))
  })

  # reactive: load betas for selected ticker
  betas_long <- reactive({
    req(input$ticker) # wait for choice

    # the path to the input files
    path <- here("output", input$ticker,
                 glue("{input$ticker}_beta.rds"))

    # display message if the file cannot be found
    validate(need(file.exists(path),
                  "No beta file found for that ticker."))

    # pivot betas to wide format
    readRDS(path) %>%
      pivot_longer(ends_with("_est"),
                   names_to  = "factor",
                   names_pattern = "(.*)_est$",
                   values_to = "beta")
  })

  # render plot to screen
  output$betaPlot <- renderPlot({
    ggplot(betas_long() %>% filter(factor != "(Intercept)"),
           aes(x = date, y = beta, colour = factor)) +
      geom_line() +
      theme_minimal() +
      labs(x = NULL, y = "Beta",
           title = glue("Rolling Factor Betas – {input$ticker}"))
  })

}

shinyApp(ui, server)

# To run:
# docker compose run --rm -p 3838:3838 r-model \
# Rscript -e "shiny::runApp('shiny', host='0.0.0.0', port=3838)"