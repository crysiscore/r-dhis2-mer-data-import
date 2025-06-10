ui <- dashboardPage(
  # useShinyjs(),  # Set up shiny to use shinyjs 
  dashboardHeader(title = "M&E Data tools", dropdownMenu(type = "notifications",
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
      #menuItem("Dashboard", tabName = "dashboard", icon = icon("dashboard")),
      menuItem("e-Analysis Upload", tabName = "widgets", icon = icon("th")),
      menuItem("DATIM Export", tabName = "dashboard", icon = icon("cloud-upload")),
      menuItem("ATS Data Export", tabName = "ats", icon = icon("th-list")),
      menuItem("Configuracao", tabName = "configuration", icon = icon("book"))
    )
  ),
  dashboardBody(
    tags$head(
      tags$link(rel = "stylesheet", type = "text/css", href = "dark_mode.css")
    ),
    tabItems( 
      # First tab content
      tabItem(tabName = "widgets",
              # Sidebar layout with input and output definitions
              sidebarLayout(
                
                # Sidebar panel for inputs
                sidebarPanel(
                  
                  # Input: Select a file to import do DHIS2
                  fileInput("file1", "Selecione o Ficheiro",
                            multiple = FALSE,
                            accept = c( "application/vnd.ms-excel","application/vnd.openxmlformats-officedocument.spreadsheetml.sheet")),
                  
                  # Horizontal line ----
                  # Output: Formatted text for caption ----
                  h5(id="instruction", textOutput("instruction", container = span),style="color:red"),
                  
                  tags$hr(),
                  
                  awesomeRadio("province", "Escolha uma Provincia: ",
                               choices = c("Maputo","Gaza"),
                               selected = "",
                               status = "success"),
                  tags$hr(),
                  # Input: Select separator ----
                  awesomeRadio("dhis_datasets", "DHIS2 Datasets",
                               choices = mer_datasets_names,
                               selected = "",
                               status = "success"),
                  
                  # Horizontal line ----
                  tags$hr(),
                  
                  #  Create a group of checkboxes : Indicadores
                  hidden(div(
                    checkboxGroupButtons(
                      inputId = "chkbxIndicatorsGroup",
                      label = "Indicadores:",
                      choices = c('')
                    )
                  )), 
                  
                  tags$hr(),
                  hidden(div(
                    awesomeCheckbox(
                      inputId = "chkbxDatim",
                      label = "MER - DATIM FORM", 
                      value = FALSE
                    )
                  )),
                  # Horizontal line ----
                  tags$hr(),
                  
                  # Horizontal line ----
                  hidden(div(
                    awesomeCheckboxGroup(
                      inputId = "chkbxUsGroup",
                      label = "U. Sanitarias:",
                      choices = c("opt1","opt2"),
                      inline = TRUE, 
                      status = "primary"
                    )
                  )),
                  
                  tags$hr(),
                  
                  hidden(div(
                    pickerInput(
                      inputId = "chkbxPeriodGroup",
                      label = "Periodo          :     ", 
                      selected = NULL,
                      multiple = TRUE,
                      options = pickerOptions(maxOptions = 1,`live-search` = TRUE),
                      choices = vec_reporting_periods,
                      width = '60%'
                    )
                  )),
                  # Horizontal line ----
                  tags$hr(),
                  
                  
                  # Submit buttons
                  # UI function
                  actionButtonStyled(inputId="btn_reset", label="Limpar Campos   ",
                                     btn_type = "button", type = "default", class = "btn-sm"),
                  actionButtonStyled(inputId="btn_checks_before_upload", label="Run Checks",
                                     btn_type = "button", type = "warning", class = "btn-sm"),
                  
                  hidden(div(
                    actionButtonStyled(
                      inputId="btn_upload",
                      label="Upload  data ",
                      btn_type = "button",
                      type = "primary",
                      class = "btn-sm"
                    )
                  ))
                  
                  
                ),
                
                # Main panel for displaying outputs ----
                mainPanel(
                  fluidRow(
                    tabBox(
                      title = "Resultados",
                      # The id lets us use input$tabset1 on the server to find the current tab
                      id = "tabset1", height = "750px", width = "680px",
                      tabPanel("Status de execucao",box( title = "Status de execucao", status = "primary", height = 
                                                           "650px",width = "12",solidHeader = T, 
                                                         column(width = 12,  DT::dataTableOutput("tbl_exec_log"),style = "height:580px; overflow-y: scroll;overflow-x: scroll;"
                                                         )  ) ),
                      tabPanel("Avisos",box( title = "Warnings", status = "primary", height = 
                                               "650px",width = "12",solidHeader = T, 
                                             column(width = 12,  DT::dataTableOutput("tbl_warning_log"),style = "height:580px; overflow-y: scroll;overflow-x: scroll;"
                                             )  )),
                      tabPanel("Erros de Integridade",  box( title = "Erros de integridade", status = "primary", height = 
                                                               "650px",width = "12",solidHeader = T, 
                                                             column(width = 12,  DT::dataTableOutput("tbl_integrity_errors"),style = "height:580px; overflow-y: scroll;overflow-x: scroll;"
                                                             )  ))
                    ) )
                  
                  # fluidRow(
                  #   tabBox(
                  #     title = "Indicadores",
                  #     # The id lets us use input$tabset1 on the server to find the current tab
                  #     id = "tab_indicadores", height = "850px", width = "680px"
                  #   ))
                  
                  # Output: Formatted text for caption ----
                  #h3(textOutput("caption", container = span)),
                  # fluidRow(
                  #   box( title = "Status de execucao", status = "primary", height = 
                  #          "365",width = "12",solidHeader = T, 
                  #        column(width = 12,  DT::dataTableOutput("tbl_exec_log"),style = "height:300px; overflow-y: scroll;overflow-x: scroll;"
                  #        )  )  ) ,
                  # fluidRow(
                  #   box( title = "Warnings", status = "primary", height = 
                  #          "465",width = "12",solidHeader = T, 
                  #        column(width = 12,  DT::dataTableOutput("tbl_warning_log"),style = "height:400px; overflow-y: scroll;overflow-x: scroll;"
                  #        )  )  ) ,
                  # fluidRow(
                  #   box( title = "Erros de integridade", status = "primary", height = 
                  #          "465",width = "12",solidHeader = T, 
                  #        column(width = 12,  DT::dataTableOutput("tbl_integrity_errors"),style = "height:400px; overflow-y: scroll;overflow-x: scroll;"
                  #        )  )  ) ,
                  # Output: Data file ----
                  #tableOutput("contents"),
                  #tableOutput("contents_error"),
                  #tableOutput("contents_emptu")
                )
                
              )
      )  ,
      
      tabItem(tabName = "dashboard",
              
              sidebarLayout(
                # Sidebar panel for inputs ----
                sidebarPanel(
                  
                  
                  awesomeRadio("datim_reproting_provinces", "Escolha uma Provincia: ",
                               choices = c("Maputo","Gaza"),
                               selected = "",
                               status = "success"),
                  tags$hr(),
                  
                  pickerInput(
                    inputId = "chkbxDatimPeriodGroup",
                    label = "Periodo de submissao    :     ", 
                    selected = NULL,
                    multiple = TRUE,
                    options = pickerOptions(maxOptions = 1,`live-search` = TRUE),
                    choices = vec_datim_reporting_periods,
                    # options = list(
                    #   maxOptions = 1,
                    #   `live-search` = TRUE
                    #   ),
                    width = '60%'
                  ) ,
                  
                  tags$hr(),
                  
                  actionButtonStyled(inputId="btn_downlaod_mer_datim", label="Data Download  ",
                                     btn_type = "button", type = "default", class = "btn-sm"),
                  
                  tags$hr(),
                  
                  verbatimTextOutput("txt_datim_logs")
                ) ,
                
                
                
                
                # Main panel for displaying outputs ----
                mainPanel(
                  fluidRow(
                    tabBox(
                      title = "Mer Results",
                      # The id lets us use input$tabset1 on the server to find the current tab
                      id = "tabset1", height = "750px", width = "730px",
                      tabPanel("Datim - Facility Based",box( title = "Dataset", status = "primary", height = 
                                                               "650px",width = "12",solidHeader = T, 
                                                             column(width = 12,  DT::dataTableOutput("data_tbl_datim_dataset"),style = "height:580px; overflow-y: scroll;overflow-x: scroll;"
                                                             )  ) ),
                      tabPanel("CCS - Facility Based",box( title = "Dataset", status = "primary", height = 
                                                             "650px",width = "12",solidHeader = T, 
                                                           column(width = 12,  DT::dataTableOutput("data_tbl_ccs_warnings"),style = "height:580px; overflow-y: scroll;overflow-x: scroll;"
                                                           )  ))
                    ) )
                  
                  
                )
                
              )
      ) ,
      
      tabItem(tabName = "ats",
              
              sidebarLayout(
                # Sidebar panel for inputs ----
                sidebarPanel(
                  
                  pickerInput(
                    inputId = "chkbxAtsStages",
                    label = "Estagio do Programa   :     ", 
                    selected = NULL,
                    multiple = FALSE,
                    options = pickerOptions(maxOptions = 1,`live-search` = TRUE),
                    choices = c(),
                    # options = list(
                    #   maxOptions = 1,
                    #   `live-search` = TRUE
                    #   ),
                    width = '60%'
                  ) ,
                  
                  tags$hr(),
                  
                  # UI function
                  actionButtonStyled(inputId="btn_load_ats_stages", label="Carregar Estagios ",
                                     btn_type = "button", type = "default", class = "btn-sm"),
                  actionButtonStyled(inputId="btn_download_stage_data", label="Baixar eventos",
                                     btn_type = "button", type = "warning", class = "btn-sm"),
                  
                  tags$hr(),
                  
                  verbatimTextOutput("txt_logs_ats")
                ) ,
                
                
                
                
                # Main panel for displaying outputs ----
                mainPanel(
                  fluidRow(
                    tabBox(
                      title = "Events Export",
                      # The id lets us use input$tabset1 on the server to find the current tab
                      id = "tabset_ats", height = "750px", width = "730px",
                      tabPanel("Data Values",box( title = "Events", status = "primary", height = 
                                                    "650px",width = "12",solidHeader = T, 
                                                  column(width = 12,  DT::dataTableOutput("df_ats_program_stages"),style = "height:580px; overflow-y: scroll;overflow-x: scroll;"
                                                  )  ) )
                    ) )
                  
                  
                )
                
              )
      )
      
    )
  ) ,
  useShinyjs() # Set up shiny to use shinyjs 
)