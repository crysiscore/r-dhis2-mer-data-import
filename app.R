library(shiny)
library(jsonlite)
library(dplyr)
library(readxl)
library(dipsaus)


source(file = 'paramConfig.R') # Carrega os paramentros 
setwd(wd)

# Define UI for data upload app ----
ui <- fluidPage(

  tags$style(
    ".h4 {
      color: red;
    }
    #instruction {
      color: red;
    }
    "
  ),
  # App title ----
  titlePanel("CCS DHIS2 data upload"),

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
      h5(id="instruction", textOutput("instruction", container = span)),
      
      tags$hr(),

      # Input: Select separator ----
      radioButtons("dhis_datasets", "DHIS2 Datasets",
                   choices = mer_datasets_names,
                   selected = ""),

      # Horizontal line ----
      tags$hr(),

      # Input: Create a group of checkboxes that can be used to toggle multiple choices independently. The server will receive the input as a character vector of the selected values.
      checkboxGroupInput("chkbxUsGroup", "Unidades Sanitarias: "
                        ) ,
      
      # Horizontal line ----
      tags$hr(),
      # Submit button
      # UI function
      actionButtonStyled(inputId="btn_checks_before_upload", label="Run Checks",
                         btn_type = "button", type = "warning", class = "btn-sm"),
      
      actionButtonStyled(inputId="btn_checks_upload", label="Upload",
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

# Define server logic to read selected file ----
server <- function(input, output) {
  
  # DIsable the button on start
  updateActionButtonStyled( getDefaultReactiveDomain(), "btn_checks_before_upload", disabled = TRUE  )
  updateActionButtonStyled( getDefaultReactiveDomain(), "btn_checks_upload",  disabled = TRUE  )
  is_file_ok <- FALSE
  
  observe( {
   
    req(input$file1)
    vec_sheets <-  c()
   
     tryCatch(
      {
        vec_sheets <- excel_sheets(path = input$file1$datapath)
        if(length(vec_sheets)> 0 ){
          
       
          # verifica se o checkbox dataset foi selecionado
          dataset = input$dhis_datasets
          if(length(dataset)==0){
            output$instruction <- renderText({  "Selecione o dataset & US" })
            
          } else if(dataset %in% mer_datasets_names  ){
            
            output$instruction <- renderText({ "" })
            is_file_ok <- TRUE
            print(paste0("You have chosen: ", input$dhis_datasets))
            
            #updateActionButtonStyled( getDefaultReactiveDomain(), "btn_checks_before_upload", disabled = FALSE)
            
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

  if(is_file_ok){
    
    # Prencher checkboxgroup das US atraves do ficheiro a ser importado, cada item representa uma folha (sheet) no ficheiro.
    updateCheckboxGroupInput(getDefaultReactiveDomain(), "chkbxUsGroup",
                             label = paste("Unidades Sanitarias: ", length(vec_sheets)),
                             choiceNames = as.list(getUsNameFromSheetNames(vec_sheets)),
                             choiceValues = as.list(vec_sheets),
                             selected = "")
  }
  
 
  

  output$contents <- renderTable({

    # input$file1 will be NULL initially. After the user selects
    # and uploads a file, head of that data file by default,
    # or all rows if selected, will be shown.

    req(input$file1)

    # when reading semicolon separated files,
    # having a comma separator causes `read.csv` to error
    tryCatch(
      {
        df <- read_xlsx(path = input$file1$datapath,sheet = 1,skip = 1)
      },
      error = function(e) {
        # return a safeError if a parsing error occurs
        stop(safeError(e))
      }
    )


      return(head(df))
   

  })
 
}

# Create Shiny app ----
shinyApp(ui, server)
