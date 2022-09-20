
server <- function(input, output) {
  
  # Create user environment to store user data
  user_env <- new.env()    
  source("misc_functions.R", local=user_env)
  source("credentials.R", local=user_env)
  attach(user_env, name="sourced_scripts")
  
  
  # 
  template_dhis2_mer_ct         <- getDhis2DatavalueSetTemplate(url.api.dhis.datasets = api_dhis_datasets, dataset.id = dataset_id_mer_ct)
  template_dhis2_mer_ats        <- getDhis2DatavalueSetTemplate(url.api.dhis.datasets = api_dhis_datasets, dataset.id = dataset_id_mer_ats)
  template_dhis2_mer_smi        <- getDhis2DatavalueSetTemplate(url.api.dhis.datasets = api_dhis_datasets, dataset.id = dataset_id_mer_smi)
  template_dhis2_mer_prevention <- getDhis2DatavalueSetTemplate(url.api.dhis.datasets = api_dhis_datasets, dataset.id = dataset_id_mer_prevention)
  template_dhis2_mer_hs         <- getDhis2DatavalueSetTemplate(url.api.dhis.datasets = api_dhis_datasets, dataset.id = dataset_id_mer_hs)
  
  # Include datavalueset from dhis on user environment
  env_bind(user_env, datavalueset_template_dhis2_mer_ct  = template_dhis2_mer_ct, datavalueset_template_dhis2_mer_ats= template_dhis2_mer_ats,
                     datavalueset_template_dhis2_mer_smi = template_dhis2_mer_smi , datavalueset_template_dhis2_mer_prevention= template_dhis2_mer_prevention ,
                     datavalueset_template_dhis2_mer_hs  =  template_dhis2_mer_hs)
  
  temporizador <-reactiveValues( started=FALSE, df_execution_log=NULL, df_warning_log=NULL)

  
  load(file = paste0(get("wd", envir = .GlobalEnv),'rdata.RData' ), envir = user_env)
 
  
  # Disable the buttons on start
  updateActionButtonStyled( getDefaultReactiveDomain(), "btn_checks_before_upload", disabled = TRUE  )
  updateActionButtonStyled( getDefaultReactiveDomain(), "btn_reset",  disabled = TRUE  )
  
  #file.copy(from = paste0(get("wd", envir = .GlobalEnv),'logs/empty_log_execution.xlsx'),to = paste0(get("wd", envir = .GlobalEnv),'logs/log_execution.xlsx'),overwrite = TRUE)
  #file.copy(from = paste0(get("wd", envir = .GlobalEnv),'logs/empty_log_execution_warning.xlsx.xlsx'),to = paste0(get("wd", envir = .GlobalEnv),'logs/log_execution_warning.xlsx'),overwrite = TRUE)
  
  # Temporizador activado pelo botao runChecks
  observe({
    invalidateLater(millis = 5000, session = getDefaultReactiveDomain())
    tmp_log_exec <-  env_get(env = user_env, nm =  "log_execution")
    tmp <- env_get(env = user_env, nm =  "error_log_dhis_import") 
    path <- env_get(env = .GlobalEnv , nm =  "wd") 
    
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
      temporizador$df_warning_log <-  tmp[2:nrow(env_get(env = user_env, nm =  "log_execution")),c(1,2,3,8,9)]
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
    shinyjs::hide(id = "btn_upload")
 
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
             shinyjs::show(id = "chkbxIndicatorsGroup", animType = "slide" )
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
    vec_indicators          <- input$chkbxIndicatorsGroup
    updateAwesomeRadio(getDefaultReactiveDomain(), inputId = "dhis_datasets",label =  "DHIS2 Datasets",
                       choices = mer_datasets_names,
                       selected = ""       )
    updatePickerInput(getDefaultReactiveDomain(), "chkbxUsGroup",
                      label = "U. Sanitarias: ",
                      choices =  list(),
                      options = list(
                        `live-search` = TRUE)
    )
    updateCheckboxGroupButtons(getDefaultReactiveDomain(),"chkbxIndicatorsGroup",label = "",choices = c("")
    )
    updateActionButtonStyled( getDefaultReactiveDomain(), "btn_checks_before_upload", disabled = TRUE  )

    output$instruction <- renderText({  "" })
    updateActionButtonStyled( getDefaultReactiveDomain(), "btn_reset",  disabled = TRUE  )
    output$tbl_integrity_errors <- renderDataTable({
    df <- read_xlsx(path = paste0(wd,'errors/template_errors.xlsx'))
    datatable( df[0 ,], options = list(paging = TRUE))
    })
    
    load(file = paste0(get("wd", envir = .GlobalEnv),'rdata.RData' ), envir = user_env)
    for (indicator in vec_indicators) {
      removeTab(inputId = "tab_indicadores", target =indicator)
    }
    
    shinyjs::hide(id = "chkbxUsGroup")
    shinyjs::hide(id = "chkbxIndicatorsGroup")
    shinyjs::hide(id = "chkbxPeriodGroup")
    shinyjs::hide(id = "btn_upload")
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
      shinyjs::hide(id = "btn_upload")
      shinyjs::hide(id = "chkbxPeriodGroup")

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
      shinyjs::show(id = "chkbxUsGroup", animType = "slide" )
      updatePickerInput(getDefaultReactiveDomain(), "chkbxUsGroup",
                        label = paste("U. Sanitarias:(", length(vec_sheets),")" ),
                        choices =  setNames(as.list(vec_sheets), getUsNameFromSheetNames(vec_sheets)),
                        selected = NULL
                               )

      shinyjs::hide(id = "btn_upload")
      shinyjs::hide(id = "chkbxPeriodGroup")
      
    } 
    
  })
  
  # Observe reset btn check consistancy
  observeEvent(input$btn_checks_before_upload, {

    vec_temp_dsnames        <- get('mer_datasets_names', envir = .GlobalEnv)
    file                    <- input$file1
    isolate(temporizador$started <- TRUE)
    file_to_import          <- file$datapath
    dataset_name            <- input$dhis_datasets
    ds_name                 <- names(which(vec_temp_dsnames==dataset_name))
    excell_mapping_template <- getTemplateDatasetName(ds_name)
    vec_indicators          <-input$chkbxIndicatorsGroup
    vec_selected_us         <-  input$chkbxUsGroup
    
    message("File :", file_to_import)
    message("Dataset name: ", ds_name)
    message("Template name: ", excell_mapping_template)
    message("Indicators: ",vec_indicators)
    message("US: ",vec_selected_us)
    
    status <- checkDataConsistency(excell.mapping.template =excell_mapping_template , file.to.import=file_to_import ,dataset.name =ds_name , sheet.name=vec_selected_us, vec.indicators=vec_indicators, user.env = user_env )

    if(status=='Integrity error'){
      shinyalert("Erro de integridade de dados", "Por favor veja os logs e tente novamente", type = "error")
      shinyjs::hide(id = "btn_upload")
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

      

      
     lapply(vec_indicators,function(x) {

          local_x <- x
          appendTab("tab_indicadores",
                                 tabPanel( local_x , box( title = local_x, status = "primary", height =  "720px",width = "12",solidHeader = T,... =
                                                        column(width = 12,  DT::dataTableOutput(env_get(env = user_env ,nm =  paste('DF_',gsub(" ", "", local_x, fixed = TRUE) , sep=''))   %>%
                                                                                                   datatable ( extensions = c('Buttons'),
                                                                                                               options = list( lengthMenu = list(c(5, 15, -1), c('5', '15', 'All')),
                                                                                                                               pageLength = 15,
                                                                                                                               dom = 'Blfrtip',
                                                                                                                               buttons = list(
                                                                                                                                 list(extend = 'excel', title = NULL),
                                                                                                                                 'pdf',
                                                                                                                                 'print'  ) )) ),style = "height:620px; overflow-y: scroll;overflow-x: scroll;"
                                                        )  ) ),
                                 session = getDefaultReactiveDomain()
                       )





      } )
      
      

      
      shinyalert("Execucao Terminada", "Alguns campos estao Vazios, verifique a tabela de avisos ", type = "warning")
   
      
      
      
      
      
      
      
      
      
      
       #   lapply(vec_indicators, function(x) {
       #   
       #     local({
       #       local_x <- x
       #   dt_id <- paste0('data_table_',gsub(" ", "", local_x, fixed = TRUE) )
       #   message(dt_id)
       #   delay(2000, appendTab("tab_indicadores",
       #             tabPanel( local_x , box( title = local_x, status = "primary", height =  "720px",width = "12",solidHeader = T,... =
       #                                    column(width = 12,  DT::dataTableOutput(outputId = dt_id ),style = "height:620px; overflow-y: scroll;overflow-x: scroll;"
       #                                    )  ) ),
       #             session = getDefaultReactiveDomain()
       #   ) )
       #   
       #   delay(2000, 
       #   output[[dt_id]]  <- DT::renderDataTable( env_get(env = user_env ,nm =  paste('DF_',gsub(" ", "", local_x, fixed = TRUE) , sep='')) %>% 
       #                                              datatable ( extensions = c('Buttons'),
       #                                                           options = list( lengthMenu = list(c(5, 15, -1), c('5', '15', 'All')),
       #                                                           pageLength = 15,
       #                                                           dom = 'Blfrtip',
       #                                                           buttons = list(
       #                                                             list(extend = 'excel', title = NULL),
       #                                                             'pdf',
       #                                                             'print'  ) )) )
       # 
       #   )
       #   message(nrow(env_get(env = user_env ,nm =  paste('DF_',gsub(" ", "", local_x, fixed = TRUE) , sep=''))))
       # })
       # 
       #   })
      
    # for(indicator in vec_indicators) {
    #   
    # 
    #  local({
    #    ind <- indicator
    #    dt_id <- paste0('data_table_',gsub(" ", "", ind, fixed = TRUE) )
    #   appendTab("tab_indicadores",
    #             tabPanel( ind , box( title = ind, status = "primary", height =  "720px",width = "12",solidHeader = T,... =
    #                                          column(width = 12,  DT::dataTableOutput(outputId = dt_id ),style = "height:620px; overflow-y: scroll;overflow-x: scroll;"
    #                                          )  ) ),
    #             session = getDefaultReactiveDomain()
    #   )
    #   
    #   # Mostrar ns datatables os indicadores processados
    #   
    #   message("Data table: ",dt_id)
    #   
    #   df <-  env_get(env = user_env ,nm =  paste('DF_',gsub(" ", "", indicator, fixed = TRUE) , sep=''))
    #   message(nrow(df))
    #   delay( 2000,
    #   output[[dt_id]] <<- DT::renderDataTable(a , extensions = c('Buttons'),
    #                                           options = list( lengthMenu = list(c(5, 15, -1), c('5', '15', 'All')),
    #                                                           pageLength = 15,
    #                                                           dom = 'Blfrtip',
    #                                                           buttons = list(
    #                                                             list(extend = 'excel', title = NULL),
    #                                                             'pdf',
    #                                                             'print'  ) ))
    #  )
    #   
    #   env_poke(env = user_env ,nm =  "temp_df",value =  df)
    #   
    #   
    # })
    #  
    #  
    # 
    # }
    # Mostrar o botao Upload
      shinyjs::show(id = "btn_upload",animType = "slide")
      shinyjs::show(id = "chkbxPeriodGroup")
   
    }
    
  })
  
  # Observe UPLOAD btn 
  observeEvent(input$btn_upload, {
    

    vec_temp_dsnames <- env_get(env = .GlobalEnv, nm =  'mer_datasets_names' )
    dataset_name     <- input$dhis_datasets
    ds_name          <- names(which(vec_temp_dsnames==dataset_name))
    dataset_id       <- mer_datasets_ids[which(names(mer_datasets_ids)==ds_name)][[1]]
    vec_indicators   <- input$chkbxIndicatorsGroup
    vec_selected_us  <- input$chkbxUsGroup
    us_name          <- getUsNameFromSheetNames(vec_selected_us)
    submission_date  <- as.character(Sys.Date())
    org_unit         <- us_names_ids_dhis[which(names(us_names_ids_dhis)==us_name )][[1]]
    period           <- input$chkbxPeriodGroup
     
    if(length(period) >0 ){
      
      message("Dataset name:    ", ds_name)
      message("Dataset id:      ", dataset_id)
      message("Indicators name: ", paste(vec_indicators,sep =  " | "))
      message("US Name :        ", us_name)
      message("Org unit:        ", org_unit)
      message("Period:          ", period)
      message("Submission date: ", submission_date)
      
      
      json_data <- merIndicatorsToJson(dataset_id,  submission_date,  period , org_unit, vec_indicators,user.env = user_env )
      #message(json_data)
      status <- apiDhisSendDataValues(json_data)
      
      if(as.integer(status$status_code)==200){
        
        shinyalert("Sucess", "Dados enviados com sucesso", type = "success")
        #TODO Registar info do upload
         upload_history = readxl::read_xlsx(path = paste0( get("wd"),'uploads/DHIS2 UPLOAD HISTORY.xlsx'))
         upload_history_empty <- upload_history[1,]
         upload_history_empty$`#`[1]         <- nrow(upload_history)+1
         upload_history_empty$upload_date[1] <- submission_date
         upload_history_empty$dataset[1]     <- ds_name
         upload_history_empty$indicadores[1] <-  paste(vec_indicators,sep =  " | ")
         upload_history_empty$periodo[1] <- period
         upload_history_empty$`org. unit`[1] <- org_unit
         upload_history_empty$status[1] <- "Sucess"
         upload_history_empty$status_code[1] <- 200
         upload_history_empty$url[1]<- status$url
         upload_history <- plyr::rbind.fill(upload_history,upload_history_empty)
         writexl::write_xlsx(x =upload_history,path = paste0( get("wd"),'uploads/DHIS2 UPLOAD HISTORY.xlsx') ,col_names = TRUE,format_headers = TRUE)
       
         # carregar variaves e dfs para armazenar logs
         #tmp_log_exec <- get('log_execution',envir = .GlobalEnv)
         tmp_log_exec <-  env_get(env = user_env, "log_execution") 
         tmp_log_exec_empty <- tmp_log_exec[1,]
         
         #Indicar a tarefa em execucao: task_check_consistency_1
         tmp_log_exec_empty$Datetime[1] <- substr(x = Sys.time(),start = 1, stop = 22)
         tmp_log_exec_empty$US[1] <- us_name
         tmp_log_exec_empty$Dataset[1] <- ds_name
         tmp_log_exec_empty$task[1] <- "Sending data to DHIS2"
         tmp_log_exec_empty$status[1] <- "ok"
         tmp_log_exec <- plyr::rbind.fill(tmp_log_exec,tmp_log_exec_empty )
         #assign(x = "log_execution",value =tmp_log_exec, envir = envir )
         env_poke(env = user_env ,nm =  "log_execution",value =  tmp_log_exec)
         #df_warnings <-  get("error_log_dhis_import", user_env = envir)
         df_warnings <-  env_get(env = user_env, "error_log_dhis_import") 
         df_warnings<- df_warnings[2:nrow(df_warnings),]
         saveLogUploadedIndicators(us.name = us_name, vec.indicators = vec_indicators,upload.date =submission_date,period =period , df.warnings = df_warnings)
         
         # Reset Panes after upload
         shinyjs::hide(id = "chkbxPeriodGroup")
         shinyjs::hide(id = "btn_upload")
         output$tbl_integrity_errors <- renderDataTable({
           df <- read_xlsx(path = paste0(wd,'errors/template_errors.xlsx'))
           datatable( df[0 ,], options = list(paging = TRUE))
         })
         
         load(file = paste0(get("wd", envir = .GlobalEnv),'rdata.RData' ), envir = user_env)
         for (indicator in vec_indicators) {
           removeTab(inputId = "tab_indicadores", target = indicator)
         }
         
      } else {
        
        shinyalert("Erro", "Erro durante o envio de dados", type = "error")
       #TODO  gravar erro  mostrar
        upload_history = readxl::read_xlsx(path = paste0( get("wd"),'uploads/DHIS2 UPLOAD HISTORY.xlsx'))
        upload_history_empty <- upload_history[1,]
        upload_history_empty$`#`[1]         <- nrow(upload_history)+1
        upload_history_empty$upload_date[1] <- submission_date
        upload_history_empty$dataset[1]     <- ds_name
        upload_history_empty$indicadores[1] <- paste(vec_indicators,sep =  " | ")
        upload_history_empty$periodo[1] <- period
        upload_history_empty$`org. unit`[1] <- org_unit
        upload_history_empty$status[1] <- "Error"
        upload_history_empty$status_code[1] <- as.integer(status$status_code)
        upload_history_empty$url[1] <- status$url
        upload_history <- plyr::rbind.fill(upload_history,upload_history_empty)
        writexl::write_xlsx(x =upload_history,path = paste0( get("wd"),'uploads/DHIS2 UPLOAD HISTORY.xlsx') ,col_names = TRUE,format_headers = TRUE)
        # carregar variaves e dfs para armazenar logs
        tmp_log_exec <- env_get(env =  user_env , 'log_execution')
        tmp_log_exec_empty <- tmp_log_exec[1,]
        #Indicar a tarefa em execucao: task_check_consistency_1
        tmp_log_exec_empty$Datetime[1] <- substr(x = Sys.time(),start = 1, stop = 22)
        tmp_log_exec_empty$US[1] <- us_name
        tmp_log_exec_empty$Dataset[1] <- ds_name
        tmp_log_exec_empty$task[1] <- "Sending data to DHIS2"
        tmp_log_exec_empty$status[1] <- "Failed"
        tmp_log_exec <- plyr::rbind.fill(tmp_log_exec,tmp_log_exec_empty )
        env_poke(env =user_env ,nm ="log_execution" ,value =  tmp_log_exec )
        #assign(x = "log_execution",value =tmp_log_exec, envir = user_env )
        shinyjs::hide(id = "chkbxPeriodGroup")
        shinyjs::hide(id = "btn_upload")
      }
      
    
    }  else {
      
      shinyalert("Aviso", "Selecione  o periodo", type = "warning")
    }
  
    #dataset.id, complete.date, period , org.unit, vec.indicators
   
    
    
  })
  
  
}
