## app.R ##
library(shinydashboard)
library(shiny)
library(jsonlite)
library(dplyr)
library(readxl)
library(dipsaus)
library(shinyWidgets)

source(file = 'paramConfig.R') # Carrega os paramentros 
setwd(wd)


ui <- dashboardPage(
  
  dashboardHeader(title = "CCS DHIS2 Data upload", dropdownMenu(type = "notifications",
                                                                notificationItem(
                                                                  text = "5 new users today",
                                                                  icon("users")
                                                                ),
                                                                notificationItem(
                                                                  text = "12 items delivered",
                                                                  icon("truck"),
                                                                  status = "success"
                                                                ),
                                                                notificationItem(
                                                                  text = "Server load at 86%",
                                                                  icon = icon("exclamation-triangle"),
                                                                  status = "warning"
                                                                )
  )),
  dashboardSidebar(
    sidebarMenu(
      id = "menu",
      menuItem("Dashboard", tabName = "dashboard", icon = icon("dashboard")),
      menuItem("Upload", tabName = "widgets", icon = icon("th"))
    )
  ),
  dashboardBody(
    tabItems( 
      # First tab content
      tabItem(tabName = "dashboard",
              fluidRow(
                box(plotOutput("plot1", height = 250)),
                
                box(
                  title = "Controls",
                  sliderInput("slider", "Number of observations:", 1, 100, 50)
                )
              )
      ),
      
      # Second tab content
      tabItem(tabName = "widgets",
              # Sidebar layout with input and output definitions ----
              sidebarLayout(
                
                # Sidebar panel for inputs ----
                sidebarPanel(
                  
                  # Input: Select a file to import do DHIS2 ----
                  fileInput("file1", "Selecione o Ficheiro",
                            multiple = FALSE,
                            accept = c( "application/vnd.ms-excel","application/vnd.openxmlformats-officedocument.spreadsheetml.sheet")),
                  
                  # Horizontal line ----
                  # Output: Formatted text for caption ----
                  h5(id="instruction", textOutput("instruction", container = span),style="color:red"),
                  
                  tags$hr(),
                  
                  # Input: Select separator ----
                  awesomeRadio("dhis_datasets", "DHIS2 Datasets",
                               choices = mer_datasets_names,
                               selected = "",
                               status = "success"),
                  
                  # Horizontal line ----
                  tags$hr(),
                  
                  # Input: Create a group of checkboxes that can be used to toggle multiple choices independently. The server will receive the input as a character vector of the selected values.
                  checkboxGroupInput("chkbxUsGroup", "Unidades Sanitarias: "
                  ) ,
                  
                  # Horizontal line ----
                  tags$hr(),
                  # Submit button
                  # UI function
                  actionButtonStyled(inputId="btn_reset", label="Reset fields   ",
                                     btn_type = "button", type = "default", class = "btn-sm"),
                  actionButtonStyled(inputId="btn_checks_before_upload", label="Run Checks",
                                     btn_type = "button", type = "warning", class = "btn-sm"),
                  
                  actionButtonStyled(inputId="btn_checks_upload", label="Upload  file ",
                                     btn_type = "button", type = "primary", class = "btn-sm")
                  
                ),
                
                # Main panel for displaying outputs ----
                mainPanel(
                  
                  
                  # Output: Formatted text for caption ----
                  h3(textOutput("caption", container = span)),
                  
                  # Output: Data file ----
                  tableOutput("contents")
                  
                )
                
              )
      )
    )
  )
)

server <- function(input, output) {
  
  # Disable the buttons on start
  updateActionButtonStyled( getDefaultReactiveDomain(), "btn_checks_before_upload", disabled = TRUE  )
  updateActionButtonStyled( getDefaultReactiveDomain(), "btn_checks_upload",  disabled = TRUE  )
  updateActionButtonStyled( getDefaultReactiveDomain(), "btn_reset",  disabled = TRUE  )
  
  #Observe SideBarMenu : switch tabs on menu clicks
  observeEvent(input$switchtab, {
    newtab <- switch(input$tabs,
                     "dashboard" = "widgets",
                     "widgets" = "dashboard"
    )
    updateTabItems(session, "tabs", newtab)
  })
  
  
  # Observe  radioButtons("dhis_datasets")
  observeEvent(input$dhis_datasets, {
    
    req(input$file1)
    
    vec_sheets <-  c()
    
    tryCatch(
      {
        vec_sheets <- excel_sheets(path = input$file1$datapath)
        if(length(vec_sheets)> 0 ){
          
          
          # verifica se o checkbox dataset foi selecionado
          dataset = input$dhis_datasets
          if(length(dataset)==0){
            #output$instruction <- renderText({  "Selecione o dataset & US" })
            
          } else if(dataset %in% mer_datasets_names  ){
            
            output$instruction <- renderText({ "" })
            # Prencher checkboxgroup das US atraves do ficheiro a ser importado, cada item representa uma folha (sheet) no ficheiro.
            updateCheckboxGroupInput(getDefaultReactiveDomain(), "chkbxUsGroup",
                                     label = paste("Unidades Sanitarias: ", length(vec_sheets)),
                                     choiceNames = as.list(getUsNameFromSheetNames(vec_sheets)),
                                     choiceValues = as.list(vec_sheets),
                                     selected = "")
            #updateActionButtonStyled( getDefaultReactiveDomain(), "btn_checks_before_upload", disabled = FALSE)
            updateActionButtonStyled( getDefaultReactiveDomain(), "btn_reset", disabled = FALSE)
            output$instruction <- renderText({  "Selecione o dataset & US" })
          } 
          
          
          
          
        }
      },
      error = function(e) {
        # return a safeError if a parsing error occurs
        message(e)
        stop(safeError(e))
      }
    )
    
    
  })
  
  # Observe reset btn
  observeEvent(input$btn_reset, {
    
    updateAwesomeRadio(getDefaultReactiveDomain(), inputId = "dhis_datasets",label =  "DHIS2 Datasets",
                       choices = mer_datasets_names,
                       selected = ""       )
    updateCheckboxGroupInput(getDefaultReactiveDomain(), "chkbxUsGroup",
                             label = paste("Unidades Sanitarias: ", "0"),
                             choices = "",
                             selected = "NULL" )
    updateActionButtonStyled( getDefaultReactiveDomain(), "btn_checks_before_upload", disabled = TRUE  )
    output$instruction <- renderText({  "" })
    updateActionButtonStyled( getDefaultReactiveDomain(), "btn_reset",  disabled = TRUE  )
  
    
  })
  
  # Observe US checkboxes 
  observeEvent( input$chkbxUsGroup, {
    
    req(input$file1)
    req(input$dhis_datasets)
    
    # verifica se alguma us foi selecionada
    us_selected = input$chkbxUsGroup
    if(length(us_selected)==0){
      
    } else {
      output$instruction <- renderText({ "" })
      cat(us_selected, sep = " | ")
      #updateActionButtonStyled( getDefaultReactiveDomain(), "btn_checks_before_upload", disabled = FALSE)
      updateActionButtonStyled( getDefaultReactiveDomain(), "btn_reset", disabled = FALSE)
      updateActionButtonStyled( getDefaultReactiveDomain(), "btn_checks_before_upload", disabled = FALSE  )
    } 
    
  })
  
  
  set.seed(122)
  histdata <- rnorm(500)
  
  output$plot1 <- renderPlot({
    data <- histdata[seq_len(input$slider)]
    hist(data)
  })
}

shinyApp(ui, server)