library(shiny)


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
                         column(width = 12,  DT::dataTableOutput("tbl_warning_log"),style = "height:400px; overflow-y: scroll;overflow-x: scroll;"
                         )  )  ) ,
                  fluidRow(
                    box( title = "Erros de integridade", status = "primary", height = 
                           "465",width = "12",solidHeader = T, 
                         column(width = 12,  DT::dataTableOutput("tbl_integrity_errors"),style = "height:400px; overflow-y: scroll;overflow-x: scroll;"
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