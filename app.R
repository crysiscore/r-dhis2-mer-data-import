## app.R ##
library(shinydashboard)
library(shiny)
library(jsonlite)
library(dplyr)
library(readxl)
library(dipsaus)
library(shinyWidgets)
library(DT)

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
                  
                  #  Create a group of checkboxes : Indicadores
                  checkboxGroupButtons(
                    inputId = "chkbxIndicatorsGroup" ,
                    label = "Indicadores:",
                     choices = c('')
                    
                  ), 
                  #checkboxGroupInput("chkbxIndicatorsGroup", "Indicadores:"
                  # ) ,
                  # Horizontal line ----
                  tags$hr(),
                  
                  # Input: Create a group of checkboxes Unidades Sanitarias
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
                  
                  actionButtonStyled(inputId="btn_upload", label="Upload  file ",
                                     btn_type = "button", type = "primary", class = "btn-sm")
                  
                ),
                
                # Main panel for displaying outputs ----
                mainPanel(
                  
                  
                  # Output: Formatted text for caption ----
                  h3(textOutput("caption", container = span)),
                  fluidRow(
                    box( title = "Status de execucao", status = "primary", height = 
                           "365",width = "12",solidHeader = T, 
                         column(width = 12,  DT::dataTableOutput("tbl_exec_log"),style = "height:300px; overflow-y: scroll;overflow-x: scroll;"
                         )  )  ) ,
                  fluidRow(
                    box( title = "Warnings", status = "primary", height = 
                           "465",width = "12",solidHeader = T, 
                         column(width = 12,  DT::dataTableOutput("tbl_exec_log"),style = "height:400px; overflow-y: scroll;overflow-x: scroll;"
                         )  )  ) ,
                  
                  # Output: Data file ----
                  tableOutput("contents"),
                  tableOutput("contents_error"),
                  tableOutput("contents_emptu")
                )
                
              )
      )
    )
  )
)

server <- function(input, output) {
  
  # Disable the buttons on start
  updateActionButtonStyled( getDefaultReactiveDomain(), "btn_checks_before_upload", disabled = TRUE  )
  updateActionButtonStyled( getDefaultReactiveDomain(), "btn_upload",  disabled = TRUE  )
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
            
            # Mostras os indicadores associados ao dataset 
            
            if(dataset=='ct'){
              updateCheckboxGroupButtons(getDefaultReactiveDomain(),"chkbxIndicatorsGroup",
                                         label = "Indicadores: ",
                                         choices = vec_mer_ct_indicators,
                                         checkIcon = list(
                                           yes = tags$i(class = "fa fa-check-square", 
                                                        style = "color: steelblue"),
                                           no = tags$i(class = "fa fa-square-o", 
                                                       style = "color: steelblue"))     )
            } else if(dataset=='ats'){
              updateCheckboxGroupButtons(getDefaultReactiveDomain(),"chkbxIndicatorsGroup",
                                         label = "Indicadores: ",
                                         choices = vec_mer_ats_indicators,
                                         checkIcon = list(
                                           yes = tags$i(class = "fa fa-check-square", 
                                                        style = "color: steelblue"),
                                           no = tags$i(class = "fa fa-square-o", 
                                                       style = "color: steelblue"))     )
            } else if(dataset=='smi'){
              updateCheckboxGroupButtons(getDefaultReactiveDomain(),"chkbxIndicatorsGroup",
                                         label = "Indicadores: ",
                                         choices = vec_mer_smi_indicators,
                                         checkIcon = list(
                                           yes = tags$i(class = "fa fa-check-square", 
                                                        style = "color: steelblue"),
                                           no = tags$i(class = "fa fa-square-o", 
                                                       style = "color: steelblue"))     )
            } else if(dataset=='prevention'){
              updateCheckboxGroupButtons(getDefaultReactiveDomain(),"chkbxIndicatorsGroup",
                                         label = "Indicadores: ",
                                         choices = vec_mer_prevention_indicators,
                                         checkIcon = list(
                                           yes = tags$i(class = "fa fa-check-square", 
                                                        style = "color: steelblue"),
                                           no = tags$i(class = "fa fa-square-o", 
                                                       style = "color: steelblue"))     )
            }else if(dataset=='hs'){
              updateCheckboxGroupButtons(getDefaultReactiveDomain(),"chkbxIndicatorsGroup",
                                         label = "Indicadores: ",
                                         choices = vec_mer_hs_indicators,
                                         checkIcon = list(
                                           yes = tags$i(class = "fa fa-check-square", 
                                                        style = "color: steelblue"),
                                           no = tags$i(class = "fa fa-square-o", 
                                                       style = "color: steelblue"))     )
            } else {}
            
           
            #updateActionButtonStyled( getDefaultReactiveDomain(), "btn_checks_before_upload", disabled = FALSE)
            updateActionButtonStyled( getDefaultReactiveDomain(), "btn_reset", disabled = FALSE)
            output$instruction <- renderText({  "Selecione o dataset & Indicadores" })
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
    updateCheckboxGroupButtons(getDefaultReactiveDomain(),"chkbxIndicatorsGroup",label = "",choices = c("")
                                )
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
      #cat(us_selected, sep = " | ")
      #updateActionButtonStyled( getDefaultReactiveDomain(), "btn_checks_before_upload", disabled = FALSE)
      updateActionButtonStyled( getDefaultReactiveDomain(), "btn_reset", disabled = FALSE)
      updateActionButtonStyled( getDefaultReactiveDomain(), "btn_checks_before_upload", disabled = FALSE  )
    } 
    
  })
  
  # Observe Indicators checkboxes 
  observeEvent( input$chkbxIndicatorsGroup, {
    
    req(input$file1)
    req(input$dhis_datasets)
    vec_sheets <-  c()
    

    vec_sheets <- excel_sheets(path = input$file1$datapath)

    # verifica se alguma us foi selecionada
    indicator_selected = input$chkbxIndicatorsGroup
    if(length(indicator_selected)==0){
      
    } else {
      output$instruction <- renderText({ "" })
      #cat(indicator_selected, sep = " | ")
      updateCheckboxGroupInput(getDefaultReactiveDomain(), "chkbxUsGroup",
                               label = paste("Unidades Sanitarias: ", length(vec_sheets)),
                               choiceNames = as.list(getUsNameFromSheetNames(vec_sheets)),
                               choiceValues = as.list(vec_sheets),
                               selected = "")
      
    } 
    
  })
  
  # Observe reset btn check consistancy
  observeEvent(input$btn_checks_before_upload, {
  
    vec_temp_dsnames <- get('mer_datasets_names', envir = .GlobalEnv)
    file_to_import          <- input$file1
    dataset_name            <- input$dhis_datasets
    ds_name <- names(which(vec_temp_dsnames==dataset_name))
    excell_mapping_template <- getTemplateDatasetName(ds_name)
    vec_indicators          <-input$chkbxIndicatorsGroup
    sheet_name              <-  input$chkbxUsGroup
    
    message("File :", file_to_import)
    message("Dataset name: ", ds_name)
    message("Template name: ", excell_mapping_template)
    message("Indicators: ",vec_indicators)
    message("US: ",sheet_name)
    
    #checkDataConsistency(excell.mapping.template, file.to.import,dataset.name, sheet.name, vec.indicators )
    
  })
  
  set.seed(122)
  histdata <- rnorm(500)
  
  output$plot1 <- renderPlot({
    data <- histdata[seq_len(input$slider)]
    hist(data)
  })
}

shinyApp(ui, server)