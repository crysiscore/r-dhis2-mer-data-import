
server <- function(input, output) {
  
  # Create user environment to store session data
  user_env <- new.env()    
  wd <- env_get(env = .GlobalEnv, nm = 'wd')
  print(wd)
  source(paste0(wd,"/misc_functions.R"),  local=user_env)
  source(paste0(wd,"/credentials.R"), local=user_env)
  attach(user_env, name="sourced_scripts")
  
  # Store datim dataset extraction output here
  datim_logs <- ""
  
  # CCS DHIS2 urls
  assign( x = "dhis_conf" ,value =   as.list(jsonlite::read_json(path = 'dhisconfig.json')) ,envir =user_env )
  
  
  # 2 - DHIS2 API END POINTS : https://docs.dhis2.org/en/develop/using-the-api/dhis-core-version-237/data.html 
  dhis_conf  <- env_get(env = user_env,nm = "dhis_conf")
  api_dhis_base_url               <-  dhis_conf['e-analisys'][[1]][1]
  api_dhis_datasets               <-  dhis_conf['e-analisys'][[1]][2]
  api_dhis_datasetvalues_endpoint <-  dhis_conf['e-analisys'][[1]][3]
  assign(x = "api_dhis_base_url", value = api_dhis_base_url , envir = user_env)
  assign(x = "api_dhis_datasets", value = api_dhis_datasets , envir = user_env)
  assign(x = "api_dhis_datasetvalues_endpoint", value = api_dhis_datasetvalues_endpoint , envir = user_env)
  

  api_datim_base_url               <-  dhis_conf['dhis-datim'][[1]][1]
  api_datim_datasets               <-  dhis_conf['dhis-datim'][[1]][2]
  api_datim_datasetvalues_endpoint <-  dhis_conf['dhis-datim'][[1]][3]
  assign(x = "api_datim_base_url", value = api_datim_base_url , envir = user_env)
  assign(x = "api_datim_datasets", value = api_datim_datasets , envir = user_env)
  assign(x = "api_datim_datasetvalues_endpoint", value = api_dhis_datasetvalues_endpoint , envir = user_env)
  
  
  # load pre-existing templates
  # See templates_generator.R
   load(file = paste0(get("wd", envir = .GlobalEnv),'/dataset_templates/dataset_templates.RDATA' ),    envir = user_env)
   load(file = paste0(get("wd", envir = .GlobalEnv),'/dataset_templates/datimDataSetElementsCC.RData'), envir = user_env)
   load(file = paste0(get("wd", envir = .GlobalEnv),'/dataset_templates/datimUploadTemplate.RData'),    envir = user_env)
   load(file = paste0(get("wd", envir = .GlobalEnv),'/dataset_templates/ccsDataExchangeOrgUnits.RData'),envir = user_env)
   
   #  
   # IF deploying on the same DHIS2 Server ignore ssl certificate errors
   httr::set_config(httr::config(ssl_verifypeer = 0L, ssl_verifyhost = 0L))
   
   # load DHIS2 datavalueset  template
   #
   # api_dhis_base_url <- "http://192.168.1.10:5400"
   # api_dhis_datasets <- 'https://mail.ccsaude.org.mz:5459/api/dataSets/'
   # dataset_id_mer_datim          <- "RU5WjDrv2Hx"
   # datavalueset_template_dhis2_datim         <- getDhis2DatavalueSetTemplate(url.api.dhis.datasets = api_dhis_datasets, dataset.id = dataset_id_mer_datim)
   # save(datavalueset_template_dhis2_datim, file = 'dataset_templates/dataset_templates.RDATA') 
   template_dhis2_datim        <- env_get(env = user_env, nm =    "datavalueset_template_dhis2_datim" ) 
  
   
  
  # Bind  DHIS2 datavalueset to user environment
  env_bind(user_env,  datavalueset_template_dhis2_datim = template_dhis2_datim)
  
  #
  temporizador <-reactiveValues( started=FALSE, df_execution_log=NULL, df_warning_log=NULL , datim_logs =NULL)
  
  #
  load(file = paste0(get("wd", envir = .GlobalEnv),'/rdata.RData' ), envir = user_env)
 
  
  # Disable the buttons on start
  updateActionButtonStyled( getDefaultReactiveDomain(), "btn_checks_before_upload", disabled = TRUE  )
  updateActionButtonStyled( getDefaultReactiveDomain(), "btn_reset",  disabled = TRUE  )
  updateActionButtonStyled( getDefaultReactiveDomain(), "btn_download_stage_data",  disabled = TRUE  )

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
    df <- read_xlsx(path = paste0(get("upload_dir"),'/template_errors.xlsx'))
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
        df <- read_xlsx(path = paste0(get("upload_dir"),'/template_errors.xlsx'))
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
       updatePickerInput( getDefaultReactiveDomain(),"chkbxPeriodGroup",
                          choices = vec_datim_reporting_periods )
       
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
      tryCatch(
        #try to do this
        {
          if(is_datim_upload=="TRUE"){
            
            
            status <- apiDatimSendDataValues(json_data ,dhis.conf = env_get(env = user_env , nm = "dhis_conf"))
            
            if(as.integer(status$status_code)==200){
              
              shinyalert("Sucess", "Dados enviados com sucesso", type = "success")
              # Registar info do upload
              upload_history = readxl::read_xlsx(path = paste0( get("upload_dir"),'/DHIS2 UPLOAD HISTORY.xlsx'))
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
              writexl::write_xlsx(x =upload_history,path = paste0( get("upload_dir"),'/DHIS2 UPLOAD HISTORY.xlsx') ,col_names = TRUE,format_headers = TRUE)
              
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
              saveLogUploadedIndicators(us.name = us_name, vec.indicators = vec_indicators,upload.date =submission_date,period =period , df.warnings = df_warnings ,envir = user_env, is.datim.form = TRUE)
              
              # Reset Panes after upload
              shinyjs::hide(id = "chkbxPeriodGroup")
              shinyjs::hide(id = "btn_upload")
              output$tbl_integrity_errors <- renderDataTable({
                df <- read_xlsx(path = paste0(get("upload_dir"),'/template_errors.xlsx'))
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
                df <- read_xlsx(path = paste0(get("upload_dir"),'/template_errors.xlsx'))
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
              
              
            } 
            else {
              
              shinyalert("Erro", "Erro durante o envio de dados", type = "error")
              #  gravar erro  mostrar
              upload_history = readxl::read_xlsx(path = paste0( get("upload_dir"),'/DHIS2 UPLOAD HISTORY.xlsx'))
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
              writexl::write_xlsx(x =upload_history,path = paste0( get("upload_dir"),'/DHIS2 UPLOAD HISTORY.xlsx') ,col_names = TRUE,format_headers = TRUE)
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
                df <- read_xlsx(path = paste0(get("upload_dir"),'/template_errors.xlsx'))
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
            
          } 
          else {
            
            status <- apiDhisSendDataValues(json_data ,dhis.conf = env_get(env = user_env , nm = "dhis_conf"))
            
            if(as.integer(status$status_code)==200){
              
              shinyalert("Sucess", "Dados enviados com sucesso", type = "success")
              # Registar info do upload
              upload_history = readxl::read_xlsx(path = paste0( get("upload_dir"),'/DHIS2 UPLOAD HISTORY.xlsx'))
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
              writexl::write_xlsx(x =upload_history,path = paste0( get("upload_dir"),'/DHIS2 UPLOAD HISTORY.xlsx') ,col_names = TRUE,format_headers = TRUE)
              
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
              saveLogUploadedIndicators(us.name = us_name, vec.indicators = vec_indicators,upload.date =submission_date,period =period , df.warnings = df_warnings ,envir = user_env, is.datim.form = FALSE)
              
              # Reset Panes after upload
              shinyjs::hide(id = "chkbxPeriodGroup")
              shinyjs::hide(id = "btn_upload")
              output$tbl_integrity_errors <- renderDataTable({
                df <- read_xlsx(path = paste0(get("upload_dir"),'/template_errors.xlsx'))
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
                df <- read_xlsx(path = paste0(get("upload_dir"),'/template_errors.xlsx'))
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
              
              
            } 
            else {
              
              shinyalert("Erro", "Erro durante o envio de dados", type = "error")
              #  gravar erro  mostrar
              upload_history = readxl::read_xlsx(path = paste0( get("upload_dir"),'/DHIS2 UPLOAD HISTORY.xlsx'))
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
              writexl::write_xlsx(x =upload_history,path = paste0( get("upload_dir"),'/DHIS2 UPLOAD HISTORY.xlsx') ,col_names = TRUE,format_headers = TRUE)
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
                df <- read_xlsx(path = paste0(get("upload_dir"),'/template_errors.xlsx'))
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
            
            
          }

        },
        #if an error occurs, tell me the error
        error=function(e) {
          shinyalert("Erro", paste0("Erro durante o envio de dados, Tente novamente", as.character(e)), type = "error")
          message(e)
        },
        #if a warning occurs, tell me the warning
          warning=function(w) {
          message(w)

        }
      )
      

      
    
    }  else {
      
      shinyalert("Aviso", "Selecione  o periodo", type = "warning")
    }
    # Reset fields
    # --------------------------------------------------------------------------------------------
    # Dataset.id, complete.date, period , org.unit, vec.indicators
   
    
    
  })
  
  # Observe donwload btn  btn_downlaod_mer_datim
  observeEvent(input$btn_downlaod_mer_datim, {
    
    
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
    api_dhis_url     <- env_get(env = user_env, nm =  "api_datim_base_url") 
    dataset.id       <- env_get(env = .GlobalEnv, nm =  "dataset_id_mer_datim")
    df_datim         <- env_get(env = user_env,   nm = "df_datim" )
    
    if(length(period)==0){
      shinyalert("Info", "Selecione o Periodo!", type = "info")
      
    } else {
      for (us in hf_names[1:37] ) {
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
        
        # Remove zeros from df
        df_dataset_datim <- subset(x = df_dataset_datim, as.integer(df_dataset_datim$Value) > 0 , )
        
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
  
  # Observe btn btn_load_ats_stages 
  observeEvent(input$btn_load_ats_stages, {
    tryCatch(
      #try to do this
      {
        
        withProgress(message = 'Carregando Conceitos do DHIS      ',
                     detail = 'This may take a while...', value = 0, {
                       
                       api.dhis.base.url <-  dhis_conf['e-analisys'][[1]][1]
                       
                       incProgress(1/(3), detail = ("Carregando Org Units... " ))   
                       unidadesSanitarias <- getOrganizationUnits(api.dhis.base.url,org.unit)
                       assign(x = "unidadesSanitarias" , value = unidadesSanitarias, envir = user_env )
                       
                       incProgress(1/(3), detail = ("Carregando Data Elements... " ))           
                       # Todos data Elements do DHIS2
                       dataElements <- getDataElements(api.dhis.base.url)
                       dataElements$name <- as.character(dataElements$name)
                       dataElements$shortName <- as.character(dataElements$shortName)
                       dataElements$id <- as.character(dataElements$id)
                       
                       assign(x = "dataElements" , value = dataElements, envir = user_env )
                       incProgress(1/(3), detail = ("Carregando Estagios... " ))                     
                       # Program stages
                       programStages <- getProgramStages(api.dhis.base.url,program.id)
                       programStages$name <- as.character(programStages$name)
                       # programStages$description <- as.character(programStages$description)
                       programStages$id <- as.character(programStages$id)
                       assign(x = "programStages" , value = programStages, envir = user_env )
                       
                       updatePickerInput(getDefaultReactiveDomain(), "chkbxAtsStages",
                                         choices = setNames(programStages$id, programStages$name),
                                         selected = NULL
                       )
                       
                       
                       output$txt_logs_ats <-  renderText({ HTML(" Dados carregados com sucesso. Selecione o Estagio.")})
                       updateActionButtonStyled( getDefaultReactiveDomain(), "btn_load_ats_stages", disabled = TRUE  )
                       updateActionButtonStyled( getDefaultReactiveDomain(), "btn_download_stage_data", disabled = FALSE  )
                     })
      },
      #if an error occurs, tell me the error
      error=function(e) {
        output$txt_logs_ats <-  renderText({ HTML(paste0(" Erro durante o carregamento de estagios! ",'\n' , as.character(e) )) })
        print(e)
      },
      #if a warning occurs, tell me the warning
      warning=function(w) {
        message('A Warning Occurred')
        print(w)
        output$txt_logs_ats <-  renderText({ HTML(paste0(" Aviso! ",'\n' , as.character(w) )) })
        #return(NA)
      }
    )

    
  })
  
  # Observe btn btn_download_stage_data 
  observeEvent(input$btn_download_stage_data, {
    tryCatch(
      #try to do this
      {
        withProgress(message = 'Carregando Eventos do DHIS2     ',
                     detail = 'This may take a while...', value = 0, {
                       
         api.dhis.base.url <-  dhis_conf['e-analisys'][[1]][1]
                       
                       incProgress(1/(7), detail = ("Carregando Enrollments... " )) 
                       
                       program.id                       <- env_get(env = .GlobalEnv ,nm = "program.id" )
                       org.unit                         <- env_get(env = .GlobalEnv ,nm = "org.unit" )
                       program.stage.id.registo.diario  <-  env_get(env = .GlobalEnv ,nm = "program.stage.id.registo.diario" )
                       program.stage.id.ligacao         <-  env_get(env = .GlobalEnv ,nm = "program.stage.id.ligacao" )
                       # Get program enrollment: pi.dhis.base.url ,org.unit,program.id
                       enrollments <- getEnrollments(api.dhis.base.url ,org.unit, program.id )
                       
                       # get TrackedInstances: api.dhis.base.url,program.id,org.unit
                       
                       trackedInstances <- getTrackedInstances(api.dhis.base.url,program.id,org.unit  )
                       incProgress(1/(7), detail = ( paste0("Carregando Eventos:  " ,getStageNameByID( input$chkbxAtsStages, env_get(env = user_env,nm = "programStages")  )))) 
                       
                       # GET ALL EVENTS FROM PROGRAM STAGE : paramentros api.dhis.base.url,org.unit,program.id,program.stage.id
                       events_regist_diario <- getTrackerEvents(api.dhis.base.url,org.unit,program.id,program.stage.id.registo.diario)
                       events_regist_diario$dataElement <- as.character(events_regist_diario$dataElement)
                       events_regist_diario$programStage <- as.character(events_regist_diario$programStage)
                       events_regist_diario$dataElement <- sapply(events_regist_diario$dataElement, findDataElementByID)
                       events_regist_diario$programStage <- sapply(events_regist_diario$programStage, findProgramStageByID)
                       events_regist_diario$dataElementName <-  sapply(events_regist_diario$dataElement, findDataElementByID)
                       events_regist_diario$trackedInstance <- ""
                       
                       # GET ALL EVENTS FROM PROGRAM STAGE : paramentros api.dhis.base.url,org.unit,program.id,program.stage.id
                       incProgress(1/(7), detail = ( paste0("Carregando Eventos:  " , "Ligacao"))) 
                       events_ligacao<- getTrackerEvents(api.dhis.base.url,org.unit,program.id,program.stage.id.ligacao)
                       events_ligacao$dataElement <- as.character(events_ligacao$dataElement)
                       events_ligacao$programStage <- as.character(events_ligacao$programStage)
                       events_ligacao$dataElement <- sapply(events_ligacao$dataElement, findDataElementByID)
                       events_ligacao$programStage <- sapply(events_ligacao$programStage, findProgramStageByID)
                       events_ligacao$dataElementName <-  sapply(events_ligacao$dataElement, findDataElementByID)
                       events_ligacao$trackedInstance <- ""
                       
                       
                       
                       # Find TE by its Enrollmet
                       incProgress(1/(7), detail = ( paste0("Merge de Eventos com TrackedInstances" ))) 
                       df_ats_registo_diario  <- left_join(events_regist_diario,enrollments, by="enrollment") %>%
                         select(c("storedBy", "programStage","enrollment","dataElement", "value", "orrgUnitName" , "trackedEntity", "enrolledAt"))
                       df_ats_registo_ligacao <- left_join(events_ligacao,enrollments, by="enrollment") %>%
                         select(c("storedBy", "programStage","enrollment","dataElement", "value", "orrgUnitName" , "trackedEntity", "enrolledAt"))
                       
                       
                       # juntar os eventos aos trackedInstances
                       df_ats_events_reg_diario <- left_join(df_ats_registo_diario,trackedInstances,by="trackedEntity")
                       df_ats_events_ligacao    <- left_join(df_ats_registo_ligacao,trackedInstances,by="trackedEntity")
                       
                       # Excluir linhas duplicadas
                       df_ats_events_reg_diario   <- df_ats_events_reg_diario[!duplicated(df_ats_events_reg_diario), ]
                       df_ats_events_ligacao  <- df_ats_events_ligacao[!duplicated(df_ats_events_ligacao), ]
                       
                       #TODO
                       # Este dataset e' repetitivo, significa que pode conter mais de um valor para o mesmo dataelement
                       # portanto precisa de tratamento diferente
                       # df_ats_events_cpn      <- df_ats_events_cpn[!duplicated(df_ats_events_cpn), ]
                       
                       
                       # Transform Long to Wide
                       incProgress(1/(7), detail = "Transformando do formato Long to Wide...") 
                       df_reg_diario           <- tidyr::spread(data = df_ats_events_reg_diario,key =dataElement,value =  value)
                       df_ligacao              <- tidyr::spread(data = df_ats_events_ligacao,key =dataElement,value =  value)
                       
                       incProgress(1/(7), detail = "Rendering data... ")
                       # Juntar os df registo diario e ligacao 
                       
                       df_reg_ligacao <- left_join(df_reg_diario, df_ligacao, by="trackedInstance") %>% select(c(2:13,20))
                       
                       
                       output$df_ats_program_stages <- renderDT({
                         datatable(df_reg_ligacao ,
                                   extensions = c('Buttons'), 
                                   options = list( lengthMenu = list(c(5, 15, -1), c('5', '15', 'All')),
                                                   pageLength = 15,
                                                   dom = 'Blfrti',
                                                   buttons = list(
                                                     list(extend = 'excel', title = NULL),
                                                     'pdf',
                                                     'print'  ) ) )
                         
                         
                       })
                       
                       incProgress(1/(7), detail = "Done. ")
                       
                     })
      },
      #if an error occurs, tell me the error
      error=function(e) {
        message('An Error Occurred')
        print(e)
        output$txt_logs_ats <-  renderText({ HTML(paste0(" Erro durante o carregamento de estagios! ",'\n' , as.character(e) )) })
      },
      #if a warning occurs, tell me the warning
      warning=function(w) {
        message('A Warning Occurred')
        print(w)
        output$txt_logs_ats <-  renderText({ HTML(paste0(" Aviso! ",'\n' , as.character(w) )) })
      }
    )
    

  })
  
  
  
  
}
