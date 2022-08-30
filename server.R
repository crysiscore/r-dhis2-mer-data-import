
server <- function(input, output) {
  
  temporizador <-reactiveValues( started=FALSE, df_execution_log=NULL, df_warning_log=NULL)
  load(file = paste0(get("wd", envir = .GlobalEnv),'rdata.RData' ), envir = .GlobalEnv)
  # Disable the buttons on start
  updateActionButtonStyled( getDefaultReactiveDomain(), "btn_checks_before_upload", disabled = TRUE  )
  updateActionButtonStyled( getDefaultReactiveDomain(), "btn_upload",  disabled = TRUE  )
  updateActionButtonStyled( getDefaultReactiveDomain(), "btn_reset",  disabled = TRUE  )
  #file.copy(from = paste0(get("wd", envir = .GlobalEnv),'logs/empty_log_execution.xlsx'),to = paste0(get("wd", envir = .GlobalEnv),'logs/log_execution.xlsx'),overwrite = TRUE)
  #file.copy(from = paste0(get("wd", envir = .GlobalEnv),'logs/empty_log_execution_warning.xlsx.xlsx'),to = paste0(get("wd", envir = .GlobalEnv),'logs/log_execution_warning.xlsx'),overwrite = TRUE)
  
  # Temporizador activado pelo botao runChecks
  observe({
    invalidateLater(millis = 5000, session = getDefaultReactiveDomain())
    tmp_log_exec <-  get("log_execution", envir = .GlobalEnv)
    tmp <- get("error_log_dhis_import", envir = .GlobalEnv)
    path <- get("wd",envir = .GlobalEnv)
    
    if(isolate(temporizador$started)){
      isolate ({
        if(nrow(tmp_log_exec)>1){
          temporizador$df_execution_log <- tmp_log_exec[2:nrow(tmp_log_exec),]
        } else {  temporizador$df_execution_log <- tmp_log_exec  }

        if(nrow(tmp)>1){
          temporizador$df_warning_log <-  tmp[2:nrow(tmp),c(1,2,3,8,9)]
        } else {temporizador$df_warning_log <-  tmp[,c(1,2,3,8,9)]  }
               })
    } else  
      { 
      temporizador$df_execution_log <- tmp_log_exec
      temporizador$df_warning_log <-  tmp[2:nrow(log_execution),c(1,2,3,8,9)]
    }
  } , priority = 2)
  
  
  output$tbl_exec_log <- renderDT({
    invalidateLater(millis = 10000, session = getDefaultReactiveDomain())
    datatable( temporizador$df_execution_log,
               extensions = c('Buttons'), 
               options = list( lengthMenu = list(c(5, 15, -1), c('5', '15', 'All')),
                               pageLength = 15,
                              dom = 'Blfrti',
                              buttons = list(
                                             list(extend = 'excel', title = NULL),
                                             'pdf',
                                             'print'  ) ) )
  })
  
  output$tbl_warning_log <- renderDT({
    invalidateLater(millis = 10000, session = getDefaultReactiveDomain())
    datatable( temporizador$df_warning_log,
               extensions = c('Buttons'),
               options = list( lengthMenu = list(c(5, 15, -1), c('5', '15', 'All')),
                               pageLength = 15, 
                              dom = 'Blfrti',
                              buttons = list(
                                             list(extend = 'excel', title = NULL),
                                             'pdf',
                                             'print'  ) )   )
  })
  
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
    vec_indicators          <-input$chkbxIndicatorsGroup
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
    output$tbl_integrity_errors <- renderDataTable({
      df <- read_xlsx(path = paste0(wd,'errors/template_errors.xlsx'))
      datatable( df[0 ,], options = list(paging = TRUE))
    })
    
    load(file = paste0(get("wd", envir = .GlobalEnv),'rdata.RData' ), envir = .GlobalEnv)
    for (indicator in vec_indicators) {
      removeTab(inputId = "tab_indicadores", target =indicator)
    }
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
    file <- input$file1
    isolate(temporizador$started <- TRUE)
    file_to_import          <- file$datapath
    dataset_name            <- input$dhis_datasets
    ds_name <- names(which(vec_temp_dsnames==dataset_name))
    excell_mapping_template <- getTemplateDatasetName(ds_name)
    vec_indicators          <-input$chkbxIndicatorsGroup
    vec_selected_us              <-  input$chkbxUsGroup
    
    message("File :", file_to_import)
    message("Dataset name: ", ds_name)
    message("Template name: ", excell_mapping_template)
    message("Indicators: ",vec_indicators)
    message("US: ",vec_selected_us)
    
    status <- checkDataConsistency(excell.mapping.template =excell_mapping_template , file.to.import=file_to_import ,dataset.name =ds_name , sheet.name=vec_selected_us, vec.indicators=vec_indicators )

    if(status=='Integrity error'){
      shinyalert("Erro de integridade de dados", "Por favor veja os logs e tente novamente", type = "error")

      output$tbl_integrity_errors <- renderDT({
        df <- read_xlsx(path = paste0(wd,'errors/template_errors.xlsx'))
        datatable( df,  extensions = c('Buttons'),
                   options = list( lengthMenu = list(c(5, 15, -1), c('5', '15', 'All')),
                                   pageLength = 15,
                                  dom = 'Blfrti',
                                  buttons = list(
                                                 list(extend = 'excel', title = NULL),
                                                 'pdf',
                                                 'print'  ) ))
      })

    }
    else {
      shinyalert("Execucao Terminada", "Alguns campos estao Vazios, verifique a tabela de avisos ", type = "warning")

    for (indicator in vec_indicators) {
      appendTab("tab_indicadores",
        tabPanel(indicator ,box( title = indicator, status = "primary", height =  "720px",width = "12",solidHeader = T,
                                           column(width = 12,  DT::dataTableOutput(paste0('data_table_',indicator )),style = "height:620px; overflow-y: scroll;overflow-x: scroll;"
                                           )  ) ),

        session = getDefaultReactiveDomain()
      )
      # render indicator data
      id <- paste0('data_table_',indicator )
      message("Data table: ",id)
      df <- get(paste('DF_',gsub(" ", "", indicator, fixed = TRUE) , sep=''), envir = .GlobalEnv)

      output[[id]] <- DT::renderDataTable(df, extensions = c('Buttons'),
                                          options = list( lengthMenu = list(c(5, 15, -1), c('5', '15', 'All')),
                                                          pageLength = 15,
                                                         dom = 'Blfrtip',
                                                         buttons = list(
                                                                        list(extend = 'excel', title = NULL),
                                                                        'pdf',
                                                                        'print'  ) ))

    }

    }
    
  })
  

  

  
  
  
}
