
server <- function(input, output) {
  
  # Create user environment to store session data
  user_env <- new.env()    
  wd <- env_get(env = .GlobalEnv, nm = 'wd')
  print(wd)
  source(paste0(wd,"/misc_functions.R"),  local=user_env)
  source(paste0(wd,"/credentials.R"), local=user_env)
  attach(user_env, name="sourced_scripts")
  # store datim dataset extraction output here
  datim_logs <- ""
  
   load(file = paste0(get("wd", envir = .GlobalEnv),'/dataset_templates/dataset_templates.RDATA' ),    envir = user_env)
   load(file = paste0(get("wd", envir = .GlobalEnv),'/dataset_templates/datimDataSetElementsCC.RData'), envir = user_env)
   load(file = paste0(get("wd", envir = .GlobalEnv),'/dataset_templates/datimUploadTemplate.RData'),    envir = user_env)
   load(file = paste0(get("wd", envir = .GlobalEnv),'/dataset_templates/ccsDataExchangeOrgUnits.RData'),envir = user_env)
   
   #  
   # IF deploying on the same DHIS2 Server ignore ssl certificate errors
   httr::set_config(httr::config(ssl_verifypeer = 0L, ssl_verifyhost = 0L))
   
   template_dhis2_mer_ct         <- env_get(env = user_env, nm =    "template_dhis2_mer_ct" ) 
   template_dhis2_mer_ats        <- env_get(env = user_env, nm =    "template_dhis2_mer_ats" ) 
   template_dhis2_mer_smi        <- env_get(env = user_env, nm =    "template_dhis2_mer_smi" ) 
   template_dhis2_mer_prevention <- env_get(env = user_env, nm =    "template_dhis2_mer_prevention" ) 
   template_dhis2_mer_hs         <- env_get(env = user_env, nm =    "template_dhis2_mer_hs" ) 
   template_dhis2_mer_ats_community <- env_get(env = user_env,nm =  "template_dhis2_mer_ats_community" ) 
   
  
  # Bind  DHIS2 datavalueset to user environment
  env_bind(user_env, datavalueset_template_dhis2_mer_ct  = template_dhis2_mer_ct, datavalueset_template_dhis2_mer_ats= template_dhis2_mer_ats,
                     datavalueset_template_dhis2_mer_smi = template_dhis2_mer_smi , datavalueset_template_dhis2_mer_prevention= template_dhis2_mer_prevention ,
                     datavalueset_template_dhis2_mer_hs  =  template_dhis2_mer_hs, datavalueset_template_dhis2_mer_ats_community = template_dhis2_mer_ats_community)
  
  #
  temporizador <-reactiveValues( started=FALSE, df_execution_log=NULL, df_warning_log=NULL , datim_logs =NULL)
  
  load(file = paste0(get("wd", envir = .GlobalEnv),'/rdata.RData' ), envir = user_env)
 
  
  # Disable the buttons on start
  updateActionButtonStyled( getDefaultReactiveDomain(), "btn_checks_before_upload", disabled = TRUE  )
  updateActionButtonStyled( getDefaultReactiveDomain(), "btn_reset",  disabled = TRUE  )
  

  #Observe SideBarMenu : switch tabs on menu clicks
  observeEvent(input$switchtab, {
    newtab <- switch(input$tabs,
                     "dashboard" = "widgets",
                     "widgets" = "dashboard"
    )
    updateTabItems(session, "tabs", newtab)
  })
  
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
  
  output$data_tbl_datim_dataset <- renderDT({
    datatable(env_get(env = user_env,nm = "df_datim" ) ,
               extensions = c('Buttons'), 
               options = list( lengthMenu = list(c(5, 15, -1), c('5', '15', 'All')),
                               pageLength = 15,
                               dom = 'Blfrti',
                               buttons = list(
                                 list(extend = 'excel', title = NULL),
                                 'pdf',
                                 'print'  ) ) )
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
            } else if(dataset=='ats_community'){
              updateCheckboxGroupButtons(getDefaultReactiveDomain(),"chkbxIndicatorsGroup",
                                         label = "Indicadores: ",
                                         choices = vec_mer_ats_community,
                                         checkIcon = list(
                                           yes = tags$i(class = "fa fa-check-square", 
                                                        style = "color: steelblue"),
                                           no = tags$i(class = "fa fa-square-o", 
                                                       style = "color: steelblue"))     )
            } 
            
            
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
    df <- read_xlsx(path = paste0(wd,'/errors/template_errors.xlsx'))
    datatable( df[0 ,], options = list(paging = TRUE))
    })
    
    load(file = paste0(get("wd", envir = .GlobalEnv),'/rdata.RData' ), envir = user_env)
    # for (indicator in vec_indicators) {
    #   removeTab(inputId = "tab_indicadores", target =indicator)
    # }
    
    shinyjs::hide(id = "chkbxUsGroup")
    shinyjs::hide(id = "chkbxIndicatorsGroup")
    shinyjs::hide(id = "chkbxPeriodGroup")
    shinyjs::hide(id = "btn_upload")
    shinyjs::hide(id = "chkbxDatim")
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

      
       us.names <- getUsNameFromSheetNames(vec_sheets)
       if(length(which(is.na(us.names)))>0 ){
         shinyalert("Aviso", "Ums das sheets tem o nome vazio. Deve corrigir antes de avancar.", type = "warning")
       } else {
         updatePickerInput(getDefaultReactiveDomain(), "chkbxUsGroup",
                           label = paste("U. Sanitarias:(", length(vec_sheets),")" ),
                           choices =  setNames(as.list(vec_sheets), getUsNameFromSheetNames(vec_sheets)),
                           selected = NULL
         )
         
         shinyjs::hide(id = "btn_upload")
         shinyjs::hide(id = "chkbxPeriodGroup")
         #cat(indicator_selected, sep = " | ")
         shinyjs::show(id = "chkbxUsGroup", animType = "slide" )

       }

      
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
    
    status <- checkDataConsistency(excell.mapping.template = excell_mapping_template , file.to.import = file_to_import ,dataset.name =ds_name , sheet.name=vec_selected_us, vec.indicators=vec_indicators, user.env = user_env )

    if(status=='Integrity error'){
      shinyalert("Erro de integridade de dados", "Por favor veja os logs e tente novamente", type = "error")
      shinyjs::hide(id = "btn_upload")
      output$tbl_integrity_errors <- renderDT({
        df <- read_xlsx(path = paste0(wd,'/errors/template_errors.xlsx'))
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

      

      
     # lapply(vec_indicators,function(x) {
     # 
     #      local_x <- x
     #      appendTab("tab_indicadores",
     #                             tabPanel( local_x , box( title = local_x, status = "primary", height =  "720px",width = "12",solidHeader = T,... =
     #                                                    column(width = 12,  DT::dataTableOutput(env_get(env = user_env ,nm =  paste('DF_',gsub(" ", "", local_x, fixed = TRUE) , sep=''))   %>%
     #                                                                                               datatable ( extensions = c('Buttons'),
     #                                                                                                           options = list( lengthMenu = list(c(5, 15, -1), c('5', '15', 'All')),
     #                                                                                                                           pageLength = 15,
     #                                                                                                                           dom = 'Blfrtip',
     #                                                                                                                           buttons = list(
     #                                                                                                                             list(extend = 'excel', title = NULL),
     #                                                                                                                             'pdf',
     #                                                                                                                             'print'  ) )) ),style = "height:620px; overflow-y: scroll;overflow-x: scroll;"
     #                                                    )  ) ),
     #                             session = getDefaultReactiveDomain()
     #                   )
     # 
     # 
     # 
     # 
     # 
     #  } )
      
      

      
      shinyalert("Execucao Terminada", "Alguns campos estao Vazios, verifique a tabela de avisos ", type = "warning")
   
      
      shinyjs::show(id = "chkbxDatim")
   
      shinyjs::show(id = "btn_upload",animType = "slide")
      
      shinyjs::show(id = "chkbxPeriodGroup")
   
    }
    
  })
  observeEvent(input$chkbxDatim, {
     #TODO verificar se e importacao para datim
     is_datim_upload <- input$chkbxDatim
     message(is_datim_upload)
     if(is_datim_upload=="TRUE"){
       updatePickerInput(getDefaultReactiveDomain(),"chkbxPeriodGroup",
                         
                         choices = vec_datim_reporting_periods     )
       
     } else {
       
       updatePickerInput(getDefaultReactiveDomain(),"chkbxPeriodGroup",
                         
                         choices = vec_reporting_periods     )
     }
     # Mostrar o botao Upload
     
   } )
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
     
    # Check IF chckbox DATIM FORM UPLOAD is clicked

    is_datim_upload <- input$chkbxDatim

    if(is_datim_upload=="TRUE"){
      dataset_id <- dataset_id_mer_datim
    }
    
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
      #writeLines(text =json_data,con = 'temp_json.txt' )
      status <- apiDhisSendDataValues(json_data)
      
      if(as.integer(status$status_code)==200){
        
        shinyalert("Sucess", "Dados enviados com sucesso", type = "success")
        # Registar info do upload
         upload_history = readxl::read_xlsx(path = paste0( get("wd"),'/uploads/DHIS2 UPLOAD HISTORY.xlsx'))
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
         writexl::write_xlsx(x =upload_history,path = paste0( get("wd"),'/uploads/DHIS2 UPLOAD HISTORY.xlsx') ,col_names = TRUE,format_headers = TRUE)
       
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
         saveLogUploadedIndicators(us.name = us_name, vec.indicators = vec_indicators,upload.date =submission_date,period =period , df.warnings = df_warnings ,envir = user_env)
         
         # Reset Panes after upload
         shinyjs::hide(id = "chkbxPeriodGroup")
         shinyjs::hide(id = "btn_upload")
         output$tbl_integrity_errors <- renderDataTable({
           df <- read_xlsx(path = paste0(wd,'/errors/template_errors.xlsx'))
           datatable( df[0 ,], options = list(paging = TRUE))
         })
         
         load(file = paste0(get("wd", envir = .GlobalEnv),'/rdata.RData' ), envir = user_env)
         # for (indicator in vec_indicators) {
         #   removeTab(inputId = "tab_indicadores", target = indicator)
         # }
         
         # RESET ALL FIELDS
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
           df <- read_xlsx(path = paste0(wd,'/errors/template_errors.xlsx'))
           datatable( df[0 ,], options = list(paging = TRUE))
         })
         
         load(file = paste0(get("wd", envir = .GlobalEnv),'/rdata.RData' ), envir = user_env)
         # for (indicator in vec_indicators) {
         #   removeTab(inputId = "tab_indicadores", target =indicator)
         # }
         # 
         shinyjs::hide(id = "chkbxUsGroup")
         shinyjs::hide(id = "chkbxIndicatorsGroup")
         shinyjs::hide(id = "chkbxPeriodGroup")
         shinyjs::hide(id = "btn_upload")
         shinyjs::hide(id = "chkbxDatim")
         
         
      } else {
        
        shinyalert("Erro", "Erro durante o envio de dados", type = "error")
       #  gravar erro  mostrar
        upload_history = readxl::read_xlsx(path = paste0( get("wd"),'/uploads/DHIS2 UPLOAD HISTORY.xlsx'))
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
        writexl::write_xlsx(x =upload_history,path = paste0( get("wd"),'/uploads/DHIS2 UPLOAD HISTORY.xlsx') ,col_names = TRUE,format_headers = TRUE)
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
        
        # RESET ALL FIELDS
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
          df <- read_xlsx(path = paste0(wd,'/errors/template_errors.xlsx'))
          datatable( df[0 ,], options = list(paging = TRUE))
        })
        
        load(file = paste0(get("wd", envir = .GlobalEnv),'/rdata.RData' ), envir = user_env)
        # for (indicator in vec_indicators) {
        #   removeTab(inputId = "tab_indicadores", target =indicator)
        # }
        
        shinyjs::hide(id = "chkbxUsGroup")
        shinyjs::hide(id = "chkbxIndicatorsGroup")
        shinyjs::hide(id = "chkbxPeriodGroup")
        shinyjs::hide(id = "btn_upload")
        shinyjs::hide(id = "chkbxDatim")
      }
      
    
    }  else {
      
      shinyalert("Aviso", "Selecione  o periodo", type = "warning")
    }
    # Reset fields
    # --------------------------------------------------------------------------------------------
    # Dataset.id, complete.date, period , org.unit, vec.indicators
   
    
    
  })
  
  # Observe UPLOAD btn  btn_downlaod_mer_datim
  observeEvent(  input$btn_downlaod_mer_datim, {
    
    
    withProgress(message = 'Dados em processamento',
                 detail = 'This may take a while...', value = 0, {
    load(file = paste0(get("wd", envir = .GlobalEnv),'/dataset_templates/datimUploadTemplate.RData'),    envir = user_env)
     output$data_tbl_datim_dataset <- renderDT({
                     datatable(env_get(env = user_env,nm = "df_datim" ) ,
                               extensions = c('Buttons'), 
                               options = list( lengthMenu = list(c(5, 15, -1), c('5', '15', 'All')),
                                               pageLength = 15,
                                               dom = 'Blfrti',
                                               buttons = list(
                                                 list(extend = 'excel', title = NULL),
                                                 'pdf',
                                                 'print'  ) ) )
                   })
     output$data_tbl_ccs_warnings <- renderDT({
       datatable(env_get(env = user_env,nm = "df_datim" ) ,
                 extensions = c('Buttons'), 
                 options = list( lengthMenu = list(c(5, 15, -1), c('5', '15', 'All')),
                                 pageLength = 15,
                                 dom = 'Blfrti',
                                 buttons = list(
                                   list(extend = 'excel', title = NULL),
                                   'pdf',
                                   'print'  ) ) )
     })
     
    submission_date  <- as.character(Sys.Date())
    datim_logs       <- ""
    period           <- input$chkbxDatimPeriodGroup
    message(period)
    hf_names         <- env_get(env = .GlobalEnv, nm =  "us_names_ids_dhis") 
    api_dhis_url     <- env_get(env = .GlobalEnv, nm =  "api_dhis_base_url") 
    dataset.id       <- env_get(env = .GlobalEnv, nm =  "dataset_id_mer_datim")
    df_datim         <- env_get(env = user_env,   nm = "df_datim" )
    
    if(length(period)==0){
      shinyalert("Info", "Selecione o Periodo!", type = "info")
      
    } else {
      for (us in hf_names[1:30] ) {
        i = 0
        incProgress(1/(30), detail = paste("Processando  o dataset do : ", getUsName(us) , " " ))
        # print(us[1])
        df <-  tryCatch(
          {
            getDatimDataValueSet(api_dhis_url,dataset.id, period, us)
          },
          error=function(cond) {
            message(us, "Error - Here's the original error message:")
            message(cond)
            # Choose a return value in case of error
            return(NA)
          },
          finally={
            # message("Done getting Datavalues from MER DATIM FORM")
          }
        )
        if(!is.null(df)){
          
       
         
          df_datim   <- plyr::rbind.fill(df_datim ,df)
          #Tests
          #writexl::write_xlsx(x = df ,path = paste0(paste0(get("wd", envir = .GlobalEnv),'/downloads/','datim_',getUsName(us),'.xlsx')),col_names = TRUE,format_headers = TRUE)
          #msg        <- paste0(getUsName(us), " - Dados processados com sucesso.", '\n')
          #datim_logs =  paste(datim_logs, msg, sep = '')
      
        } else {
          message(getUsName(us), "   - Dataset esta vazio!!!")
          msg        <- paste0(getUsName(us), " - Nao contem dados neste periodo.", '\n')
          datim_logs =     paste(datim_logs, msg, sep = '')
        }
        
      }
      if(nrow(df_datim)>0){
        
        output$txt_datim_logs <-  renderText({ HTML(datim_logs)})
        
        funding_mechanism <-  env_get(env = .GlobalEnv,     nm =  "funding_mechanism") 
        
        #df_datim <- env_get(env = user_env,nm = "df_datim" )
        df_datim$DatimDataElement <- mapply(df_datim$CategoryOptionCombo,df_datim$Dataelement, FUN =  getDhisDataElement)
        df_datim$DatimCategoryOptionCombo <-  mapply(df_datim$CategoryOptionCombo,df_datim$Dataelement, FUN =  getDhisCategoryOptionCombo)
        df_datim$DatimAttributeOptionCombo <- funding_mechanism 
        #df_datim$Period <- sapply( df_datim$Period ,aDjustDhisPeriods)
        df_datim$DatimOrgUnit <- sapply(df_datim$OrgUnit, FUN =  getDhisOrgUnit)
        df_dataset_datim <- df_datim[,c(7,2,10,8,9,6)]
        names(df_dataset_datim)[1] <- "Dataelement"
        names(df_dataset_datim)[2] <- "Period"
        names(df_dataset_datim)[3] <- "OrgUnit" 
        names(df_dataset_datim)[4] <- "CategoryOptionCombo"
        names(df_dataset_datim)[5] <- "AttributeOptionCombo"
        names(df_dataset_datim)[6] <- "Value"

        df_dataset_ccs  <-  df_datim[,c(7,2,10,8,9,6,1,3,4,5)]
        
        #names(df_dat)[1] <- ""
        output$data_tbl_datim_dataset <- renderDT({
          datatable(df_dataset_datim ,
                    extensions = c('Buttons'), 
                    options = list( lengthMenu = list(c(5, 15, -1), c('5', '15', 'All')),
                                    pageLength = 15,
                                    dom = 'Blfrti',
                                    buttons = list(
                                      list(extend = 'excel', title = NULL),
                                      'pdf',
                                      'print'  ) ) )
          
    
        })
        
        output$data_tbl_ccs_warnings <- renderDT({
          datatable(df_dataset_ccs ,
                    extensions = c('Buttons'), 
                    options = list( lengthMenu = list(c(5, 15, -1), c('5', '15', 'All')),
                                    pageLength = 15,
                                    dom = 'Blfrti',
                                    buttons = list(
                                      list(extend = 'excel', title = NULL),
                                      'pdf',
                                      'print'  ) ) )
          
          
        })
      } else {
        
        
        output$txt_datim_logs <-  renderText({ HTML(datim_logs)})
        
        
        shinyalert("Erro", "Ocoreu algum erro ao processar o dataset. Veja os logs", type = "error")
        
        
        
      }
      
    }

    
  })
  })
}
