
server <- function(input, output) {
  
  # Create user environment to store session data
  user_env <- new.env()    
  wd <- env_get(env = .GlobalEnv, nm = 'wd')
  print(wd)
  source(paste0(wd,"/misc_functions.R"),  local=user_env)
  source(paste0(wd,"/conf/credentials.R"), local=user_env)
  attach(user_env, name="sourced_scripts")
  
  # Store datim dataset extraction output here
  datim_logs <- ""
  
  # CCS DHIS2 urls
  assign( x = "dhis_conf" ,value =   as.list(jsonlite::read_json(path = paste0(env_get(env = .GlobalEnv, nm = 'wd'),'/conf/dhisconfig.json')))  ,envir =user_env )
  
  
  # 2 - DHIS2 API END POINTS : https://docs.dhis2.org/en/develop/using-the-api/dhis-core-version-237/data.html 
  dhis_conf  <- env_get(env = user_env,nm = "dhis_conf")
  api_dhis_base_url               <-  dhis_conf['e-analisys'][[1]][1]
  api_dhis_datasets               <-  dhis_conf['e-analisys'][[1]][2]
  api_dhis_datasetvalues_endpoint <-  dhis_conf['e-analisys'][[1]][3]
  assign(x = "api_dhis_base_url", value = api_dhis_base_url , envir = user_env)
  assign(x = "api_dhis_datasets", value = api_dhis_datasets , envir = user_env)
  assign(x = "api_dhis_datasetvalues_endpoint", value = api_dhis_datasetvalues_endpoint , envir = user_env)
  

  api_datim_base_url               <-  dhis_conf['e-analisys'][[1]][1]
  api_datim_datasets               <-  dhis_conf['e-analisys'][[1]][2]
  api_datim_datasetvalues_endpoint <-  dhis_conf['e-analisys'][[1]][3]
  assign(x = "api_datim_base_url", value = api_datim_base_url , envir = user_env)
  assign(x = "api_datim_datasets", value = api_datim_datasets , envir = user_env)
  assign(x = "api_datim_datasetvalues_endpoint", value = api_dhis_datasetvalues_endpoint , envir = user_env)
  
  
  # load pre-existing templates
  # See templates_generator.R
   load(file = paste0(get("wd", envir = .GlobalEnv),'/dataset_templates/dataset_templates.RDATA' ),    envir = user_env) # contem todos DE do DHIS, em caso de novos formularios deve-se gerar novamente este ficheiro
   load(file = paste0(get("wd", envir = .GlobalEnv),'/dataset_templates/datimDataSetElementsCC.RData'), envir = user_env)
   load(file = paste0(get("wd", envir = .GlobalEnv),'/dataset_templates/datimUploadTemplate.RData'),    envir = user_env)
   load(file = paste0(get("wd", envir = .GlobalEnv),'/dataset_templates/ccsDataExchangeOrgUnits.RData'),envir = user_env)
   load(file = paste0(get("wd", envir = .GlobalEnv),'/dataset_templates/datimMappingTemplate.RData'), envir = user_env)
   load(file = paste0(get("wd", envir = .GlobalEnv),'/dataset_templates/datavalueset_template_dhis2_ccs_forms.RDATA'), envir = user_env)

   # IF deploying on the same DHIS2 Server ignore ssl certificate errors
   httr::set_config(httr::config(ssl_verifypeer = 0L, ssl_verifyhost = 0L))
   
   # load DHIS2  data_element templates
   template_dhis2_datim        <- env_get(env = user_env, nm =    "datavalueset_template_dhis2_datim" ) 
   template_dhis_ccs_forms   <- env_get(env = user_env, nm =     "datavalueset_template_dhis2_ccs_forms")
   
   # Bind  the templates to user environment
  env_bind(user_env,  template_dhis2_datim = template_dhis2_datim)
  env_bind(user_env,  template_dhis_ccs_forms = template_dhis_ccs_forms)
  #browser()
  
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
    invalidateLater(millis = 15000, session = getDefaultReactiveDomain())
    tmp_log_exec <-  env_get(env = user_env, nm =  "log_execution")
    tmp <- env_get(env = user_env, nm =  "error_log_dhis_import") 
    path <- env_get(env = .GlobalEnv , nm =  "wd") 
    
    if(isolate(temporizador$started)){
      isolate ({
        if(nrow(tmp_log_exec)>1){
          temporizador$df_execution_log <- tmp_log_exec[2:nrow(tmp_log_exec),]
        } else {  temporizador$df_execution_log <- tmp_log_exec  }

        if(nrow(tmp)>1){

          #temporizador$df_warning_log <-  tmp[2:nrow(tmp),c(1,2,3,8,9)]
          temporizador$df_warning_log <-  tmp[2:nrow(tmp),c(4,6,7,8,9)]
        } else {temporizador$df_warning_log <-  tmp[,c(4,2,6,7,9)]  }
               })

    } else  
      { 
      temporizador$df_execution_log <- tmp_log_exec
      #temporizador$df_warning_log <-  tmp[2:nrow(env_get(env = user_env, nm =  "log_execution")),c(1,2,3,8,9)]
      temporizador$df_warning_log <-  tmp[2:nrow(env_get(env = user_env, nm =  "log_execution")),c(4,2,6,7,9)]
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
            } else if(dataset=='non_mer_mds'){
              updateCheckboxGroupButtons(getDefaultReactiveDomain(),"chkbxIndicatorsGroup",
                                         label = "Indicadores: ",
                                         choices = vec_non_mer_mds,
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
    # Reset the province 
    updateAwesomeRadio(getDefaultReactiveDomain(), inputId = "province",label =  "Provincia",
                       choices = c("Maputo","Gaza"),
                       selected = ""       )
                       
    # updatePickerInput(getDefaultReactiveDomain(), "chkbxUsGroup",
    #                   label = "U. Sanitarias: ",
    #                   choices =  list(),
    #                   options = list(
    #                     `live-search` = TRUE)
    # )
    updateAwesomeCheckboxGroup(getDefaultReactiveDomain(), "chkbxUsGroup",
                             label = "U. Sanitarias: ",
                             choices = character(0),
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
    
    # Reset is datim upload checkbox
    updateAwesomeCheckbox(getDefaultReactiveDomain(), "chkbxDatim",
                                  value=FALSE
    )
  
    
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
    #message(vec_sheets)
    indicator_selected = input$chkbxIndicatorsGroup
    selected_province  = input$province
    
    if(length(indicator_selected)==0 || length(selected_province)==0){
      
      shinyalert("Aviso", "Selecione os indicadores e a provincia", type = "warning")
      
    } else {
      
      output$instruction <- renderText({ "" })

      # Obter os nomes das US a partir dos sheetnames
      sheetnames <- getUsNameFromSheetNames(vec_sheets,selected_province )
       us.names <- sheetnames[1]$health_facilities
       warnings <- sheetnames[1]$warnings
       
       if ( length(us.names) > 0 ) {
         
         sapply(us.names, print)
         vec_sheet_names <- getSheetNamesFormUSName(us.names , vec_sheets)
         if(length(us.names) != length(vec_sheet_names)){
           shinyalert("Aviso", "Deve rever a formatacao dos nomes das US (sheetNames) na Planilha", type = "warning")
           
         } else {
           
           updateAwesomeCheckboxGroup(getDefaultReactiveDomain(), "chkbxUsGroup",
                                      label = paste("U. Sanitarias:(", length(us.names),")" ),
                                      choices =  setNames(as.list(vec_sheet_names), us.names),
                                      selected = NULL )
           
           
           
           shinyjs::hide(id = "btn_upload")
           shinyjs::hide(id = "chkbxPeriodGroup")
           # cat(indicator_selected, sep = " | ")
           shinyjs::show(id = "chkbxUsGroup", animType = "slide" )
           shinyjs::show(id = "chkbxDatim" )
           
           if(length(warnings) > 0 )
           { 
             for (v in warnings) { shinyalert("Aviso", v , type = "warning") }  } 
           
         }
         
       } else {
         shinyalert("Aviso", "Nomes das US  nao estao padronizados. Deve corrigir antes de avancar.", type = "warning")
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
    vec_indicators          <- input$chkbxIndicatorsGroup
    vec_selected_us         <- input$chkbxUsGroup
    selected_province       <- input$province
    
    message("File :", file_to_import)
    message("Dataset name: ", ds_name)
    excell_mapping_template <- getTemplateDatasetName(ds_name)
    message("Template name: ", excell_mapping_template)
    message("Indicators: ",indicatorsToString(vec_indicators))
    message(indicatorsToString(vec_selected_us))
    counter = 0
    # verificar se e importacao para datim
    is_datim_upload <- input$chkbxDatim
    # verificar se os sheetnames tem os nomes das US 
    
    

    for (selected_us in vec_selected_us) {
      list_us<-    getUsNameFromSheetNames(selected_us, selected_province)
      us_name <- list_us$health_facilities
      warnings <-  list_us$warnings
      if(length(warnings)>0){
        for (v in warnings) {
          showNotification(paste0(v, " - Sheet Name invalido... Continuando "),session = getDefaultReactiveDomain(), duration = 3 ,type =  "warning" )
          Sys.sleep(2)
        }
      } else if(length(us_name)>0){
        # verificar se os sheetnames tem os nomes das US 
        showNotification(paste0(us_name, " - Iniciando Processamento"),session = getDefaultReactiveDomain(), duration = 3 ,type =  "message" )
        
        status <- checkDataConsistency(excell.mapping.template = excell_mapping_template , file.to.import = file_to_import ,dataset.name =ds_name , sheet.name=selected_us, vec.indicators=vec_indicators, user.env = user_env,us.name = us_name,is.datim.upload = is_datim_upload )
        
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
          output$instruction <- renderText({ paste0("Erro durante o processamento dos dados: " ,us_name, " Por favor tentar novamente" )})
          break
     
        }
        else {
          
          showNotification( paste0(us_name, " Processed sucessfully"),session = getDefaultReactiveDomain(), duration = 3 ,type =  "message" )
          Sys.sleep(2)
          counter = counter+1
          
        }
        
      } else {
        
        showNotification( paste0(us_name, "Nenhu sheetname valido encontrado.... Verifique a planilha de importacao"),session = getDefaultReactiveDomain(), duration = 5 ,type =  "message" )
        Sys.sleep(2)
        
      }

    }

   if(length(vec_selected_us)==counter){
     
     shinyjs::show(id = "chkbxDatim")
     shinyjs::show(id = "btn_upload",animType = "slide")
     shinyjs::show(id = "chkbxPeriodGroup")
     
   } else {
     
     
     
   }
    
  })
  observeEvent(input$chkbxDatim, {
     # verificar se e importacao para datim
     is_datim_upload <- input$chkbxDatim
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
    period           <- input$chkbxPeriodGroup
    submission_date  <- as.character(Sys.Date())
    selected_province  = input$province
    
    
    is_datim_upload <- input$chkbxDatim

    if(is_datim_upload=="TRUE"){
      dataset_id <- dataset_id_mer_datim
    }
    
    if(length(period) >0 ){
      
       message("Dataset name:    ", ds_name)
       message("Dataset id:      ", dataset_id)
       message("Indicators name: ", indicatorsToString(vec_indicators))
       message("Period:          ", period)
       message("Submission date: ", submission_date)
       message("Selected province: ", selected_province)    
       message("Selected us: ", vec_selected_us)
       
       
      # store us names for sucessfully sent data
      vec_us_dados_enviados <- c()
      counter = 0
      
      # select the correct us names and ids based on the selected province
      if(selected_province=="Gaza"){
        us_names_ids_dhis <- env_get(env = .GlobalEnv, nm =  "gaza_us_names_ids_dhis")
      } else {
        us_names_ids_dhis <- env_get(env = .GlobalEnv, nm =  "maputo_us_names_ids_dhis")
      }
      
      
      for (selected_us in vec_selected_us) {


        tryCatch(
          {
            
            us_name          <- getUsNameFromSheetNames(selected_us, selected_province)[1]$health_facilities
            org_unit         <- us_names_ids_dhis[which(names(us_names_ids_dhis)==us_name )][[1]]
            message("us_name:          ", us_name)
            message("org_unit:          ", org_unit)
            json_data <- merIndicatorsToJson(dataset_id,  submission_date,  period , org_unit, vec_indicators,user.env = user_env  , us_name )
            message(json_data)
            
            if(is_datim_upload=="TRUE"){

              
              status <- apiDatimSendDataValues(json_data ,dhis.conf = env_get(env = user_env , nm = "dhis_conf"),us.name = us_name)

              if(as.integer(status$status_code)==200){
                showNotification(paste0(us_name, " - Enviado com sucesso"),session = getDefaultReactiveDomain(), duration = 3 ,type =  "message" )
                vec_us_dados_enviados <- c(vec_us_dados_enviados,us_name)
                counter = counter +1
                Sys.sleep(2)
                #shinyalert("Sucess", "Dados enviados com sucesso", type = "success")
                # Registar info do upload
                #message("iniciando o upload")
                upload_history = readxl::read_xlsx(path = paste0( get("upload_dir"),'/DHIS2 UPLOAD HISTORY.xlsx'))
                upload_history_empty <- upload_history[1,]
                upload_history_empty$`#`[1]         <- nrow(upload_history)+1
                upload_history_empty$upload_date[1] <- submission_date
                upload_history_empty$dataset[1]     <- "MER DATIM"
                upload_history_empty$indicadores[1] <-  indicatorsToString(vec_indicators)
                upload_history_empty$periodo[1] <- period
                upload_history_empty$`org. unit`[1] <- us_name
                upload_history_empty$status[1] <- "Sucess"
                upload_history_empty$status_code[1] <- 200
                upload_history_empty$url[1]<- status$url
                upload_history <- plyr::rbind.fill(upload_history,upload_history_empty)

                writexl::write_xlsx(x =upload_history,path = paste0( get("upload_dir"),'/DHIS2 UPLOAD HISTORY.xlsx') ,col_names = TRUE,format_headers = TRUE)

                # carregar variaves e dfs para armazenar logs
                tmp_log_exec <-  env_get(env = user_env, "log_execution")
                tmp_log_exec_empty <- tmp_log_exec[1,]

                #Indicar a tarefa em execucao: task_check_consistency_1
                tmp_log_exec_empty$Datetime[1] <- substr(x = Sys.time(),start = 1, stop = 22)

                                tmp_log_exec_empty$Dataset[1] <- ds_name
                tmp_log_exec_empty$task[1] <- "Sending Datim data to DHIS2"
                tmp_log_exec_empty$status[1] <- "ok"
                tmp_log_exec <- plyr::rbind.fill(tmp_log_exec,tmp_log_exec_empty )
                #assign(x = "log_execution",value =tmp_log_exec, envir = envir )
                env_poke(env = user_env ,nm =  "log_execution",value =  tmp_log_exec)
                #df_warnings <-  get("error_log_dhis_import", user_env = envir)
                df_warnings <-  env_get(env = user_env, "error_log_dhis_import")
                df_warnings<- df_warnings[2:nrow(df_warnings),]
                saveLogUploadedIndicators(us.name = us_name, vec.indicators = vec_indicators,upload.date =submission_date,period =period , df.warnings = df_warnings ,user.env  = user_env, is.datim.form = TRUE,org.unit.name = us_name)

                # # Reset Panes after upload
                # shinyjs::hide(id = "chkbxPeriodGroup")
                # shinyjs::hide(id = "btn_upload")
                # output$tbl_integrity_errors <- renderDataTable({
                #   df <- read_xlsx(path = paste0(get("upload_dir"),'/template_errors.xlsx'))
                #   datatable( df[0 ,], options = list(paging = TRUE))
                # })

                #load(file = paste0(get("wd", envir = .GlobalEnv),'/rdata.RData' ), envir = user_env)
                # for (indicator in vec_indicators) {
                #   removeTab(inputId = "tab_indicadores", target = indicator)
                # }

                # RESET ALL FIELDS
                #vec_indicators          <- input$chkbxIndicatorsGroup
                # updateAwesomeRadio(getDefaultReactiveDomain(), inputId = "dhis_datasets",label =  "DHIS2 Datasets",
                #                   choices = mer_datasets_names,
                #                   selected = ""       )
                # updatePickerInput(getDefaultReactiveDomain(), "chkbxUsGroup",
                #                   label = "U. Sanitarias: ",
                #                   choices =  list(),
                #                   options = list(
                #                     `live-search` = TRUE)
                # )
                #
                # updateAwesomeCheckboxGroup(getDefaultReactiveDomain(), "chkbxUsGroup",
                #                            label = "U. Sanitarias: ",
                #                            choices =  character(0)
                # )
                # updateCheckboxGroupButtons(getDefaultReactiveDomain(),"chkbxIndicatorsGroup",label = "",choices = c("")
                # )
                # updateActionButtonStyled( getDefaultReactiveDomain(), "btn_checks_before_upload", disabled = TRUE  )
                #
                # output$instruction <- renderText({  "" })
                # updateActionButtonStyled( getDefaultReactiveDomain(), "btn_reset",  disabled = TRUE  )
                # output$tbl_integrity_errors <- renderDataTable({
                #   df <- read_xlsx(path = paste0(get("upload_dir"),'/template_errors.xlsx'))
                #   datatable( df[0 ,], options = list(paging = TRUE))
                # })
                #
                # load(file = paste0(get("wd", envir = .GlobalEnv),'/rdata.RData' ), envir = user_env)
                # # for (indicator in vec_indicators) {
                # #   removeTab(inputId = "tab_indicadores", target =indicator)
                # # }
                # #
                # shinyjs::hide(id = "chkbxUsGroup")
                # shinyjs::hide(id = "chkbxIndicatorsGroup")
                # shinyjs::hide(id = "chkbxPeriodGroup")
                # shinyjs::hide(id = "btn_upload")
                # shinyjs::hide(id = "chkbxDatim")


              }
              else {

                shinyalert("Erro", paste0(us_name," -Erro durante o envio de dados"), type = "error")
                #  gravar erro  mostrar
                upload_history = readxl::read_xlsx(path = paste0( get("upload_dir"),'/DHIS2 UPLOAD HISTORY.xlsx'))
                upload_history_empty <- upload_history[1,]
                upload_history_empty$`#`[1]         <- nrow(upload_history)+1
                upload_history_empty$upload_date[1] <- submission_date
                upload_history_empty$dataset[1]     <- ds_name
                upload_history_empty$indicadores[1] <- indicatorsToString(vec_indicators)
                upload_history_empty$periodo[1] <- period
                upload_history_empty$`org. unit`[1] <- us_name
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

                output$instruction <- renderText({  paste0("US Importadas: ", indicatorsToString(vec_us_dados_enviados)) })


                # RESET ALL FIELDS
                # vec_indicators          <- input$chkbxIndicatorsGroup
                 # updateAwesomeRadio(getDefaultReactiveDomain(), inputId = "dhis_datasets",label =  "DHIS2 Datasets",
                 #                    choices = mer_datasets_names,
                 #                   selected = ""       )
                 # 
                 #                 updateAwesomeCheckboxGroup(getDefaultReactiveDomain(), "chkbxUsGroup",
                 #                                            label = "U. Sanitarias: ",
                 #                                           choices = character(0),
                 #                 )
                 #                 updateCheckboxGroupButtons(getDefaultReactiveDomain(),"chkbxIndicatorsGroup",label = "",choices = c("")
                 #                 )
                                 updateActionButtonStyled( getDefaultReactiveDomain(), "btn_checks_before_upload", disabled = TRUE  )


                                 updateActionButtonStyled( getDefaultReactiveDomain(), "btn_reset",  disabled = TRUE  )
                                 output$tbl_integrity_errors <- renderDataTable({
                                   df <- read_xlsx(path = paste0(get("upload_dir"),'/template_errors.xlsx'))
                                   datatable( df[0 ,], options = list(paging = TRUE))
                                 })

                                 load(file = paste0(get("wd", envir = .GlobalEnv),'/rdata.RData' ), envir = user_env)


                                 #shinyjs::hide(id = "chkbxUsGroup")
                                 #shinyjs::hide(id = "chkbxIndicatorsGroup")
                                 #shinyjs::hide(id = "chkbxPeriodGroup")
                                 shinyjs::hide(id = "btn_upload")
                                 #shinyjs::hide(id = "chkbxDatim")

                                 break
              }

            }
            else {

              status <- apiDhisSendDataValues(json_data ,dhis.conf = env_get(env = user_env , nm = "dhis_conf"),us.name = us_name)

              if(as.integer(status$status_code)==200){

                showNotification(paste0(us_name, " - Enviado com sucesso"),session = getDefaultReactiveDomain(), duration = 3 ,type =  "message" )
                vec_us_dados_enviados <- c(vec_us_dados_enviados,us_name)
                counter = counter +1
                Sys.sleep(2)
                # Registar info do upload
                upload_history = readxl::read_xlsx(path = paste0( get("upload_dir"),'/DHIS2 UPLOAD HISTORY.xlsx'))
                upload_history_empty <- upload_history[1,]
                upload_history_empty$`#`[1]         <- nrow(upload_history)+1
                upload_history_empty$upload_date[1] <- submission_date
                upload_history_empty$dataset[1]     <- ds_name
                upload_history_empty$indicadores[1] <-  indicatorsToString(vec_indicators)
                upload_history_empty$periodo[1] <- period
                upload_history_empty$`org. unit`[1] <- us_name
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
                saveLogUploadedIndicators(us.name = us_name, vec.indicators = vec_indicators,upload.date =submission_date,period =period , df.warnings = df_warnings ,user.env = user_env, is.datim.form = FALSE , org.unit.name= us_name)

                # Reset Panes after upload
                # shinyjs::hide(id = "chkbxPeriodGroup")
                # shinyjs::hide(id = "btn_upload")
                # output$tbl_integrity_errors <- renderDataTable({
                #  df <- read_xlsx(path = paste0(get("upload_dir"),'/template_errors.xlsx'))
                #  datatable( df[0 ,], options = list(paging = TRUE))
                # })
                #
                # load(file = paste0(get("wd", envir = .GlobalEnv),'/rdata.RData' ), envir = user_env)

                # RESET ALL FIELDS
                # vec_indicators          <- input$chkbxIndicatorsGroup
                # updateAwesomeRadio(getDefaultReactiveDomain(), inputId = "dhis_datasets",label =  "DHIS2 Datasets",
                #                   choices = mer_datasets_names,
                #                   selected = ""       )
                # updatePickerInput(getDefaultReactiveDomain(), "chkbxUsGroup",
                #                   label = "U. Sanitarias: ",
                #                   choices =  list(),
                #                   options = list(
                #                     `live-search` = TRUE)
                # )
                # updateAwesomeCheckboxGroup(getDefaultReactiveDomain(), "chkbxUsGroup",
                #                           label = "U. Sanitarias: ",
                #                           choices = character(0),
                # )

                # updateCheckboxGroupButtons(getDefaultReactiveDomain(),"chkbxIndicatorsGroup",label = "",choices = c("")
                # )
                # updateActionButtonStyled( getDefaultReactiveDomain(), "btn_checks_before_upload", disabled = TRUE  )
                # 
                # output$instruction <- renderText({  "" })
                # updateActionButtonStyled( getDefaultReactiveDomain(), "btn_reset",  disabled = TRUE  )
                # output$tbl_integrity_errors <- renderDataTable({
                #   df <- read_xlsx(path = paste0(get("upload_dir"),'/template_errors.xlsx'))
                #   datatable( df[0 ,], options = list(paging = TRUE))
                # })
                # 
                # load(file = paste0(get("wd", envir = .GlobalEnv),'/rdata.RData' ), envir = user_env)
                # # for (indicator in vec_indicators) {
                # #   removeTab(inputId = "tab_indicadores", target =indicator)
                # # }
                # #
                # shinyjs::hide(id = "chkbxUsGroup")
                # shinyjs::hide(id = "chkbxIndicatorsGroup")
                # shinyjs::hide(id = "chkbxPeriodGroup")
                # shinyjs::hide(id = "btn_upload")
                # shinyjs::hide(id = "chkbxDatim")


              }
              else {

                shinyalert("Erro", paste0(us_name," - Erro durante o envio de dados"), type = "error")
                #  gravar erro  mostrar
                upload_history = readxl::read_xlsx(path = paste0( get("upload_dir"),'/DHIS2 UPLOAD HISTORY.xlsx'))
                upload_history_empty <- upload_history[1,]
                upload_history_empty$`#`[1]         <- nrow(upload_history)+1
                upload_history_empty$upload_date[1] <- submission_date
                upload_history_empty$dataset[1]     <- ds_name
                upload_history_empty$indicadores[1] <- indicatorsToString(vec_indicators)
                upload_history_empty$periodo[1] <- period
                upload_history_empty$`org. unit`[1] <- us_name
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

                # RESET ALL FIELDS
                #vec_indicators          <- input$chkbxIndicatorsGroup
                #updateAwesomeRadio(getDefaultReactiveDomain(), inputId = "dhis_datasets",label =  "DHIS2 Datasets",
                #                   choices = mer_datasets_names,
                #                   selected = ""       )

                # updateAwesomeCheckboxGroup(getDefaultReactiveDomain(), "chkbxUsGroup",
                #                            label = "U. Sanitarias: ",
                #                            choices = character(0),
                # )
                # updateCheckboxGroupButtons(getDefaultReactiveDomain(),"chkbxIndicatorsGroup",label = "",choices = c("")
                # )
                 updateActionButtonStyled( getDefaultReactiveDomain(), "btn_checks_before_upload", disabled = TRUE  )
                 
                # output$instruction <- renderText({  "" })
                # updateActionButtonStyled( getDefaultReactiveDomain(), "btn_reset",  disabled = TRUE  )
                 output$tbl_integrity_errors <- renderDataTable({
                   df <- read_xlsx(path = paste0(get("upload_dir"),'/template_errors.xlsx'))
                   datatable( df[0 ,], options = list(paging = TRUE))
                 })
                 
                 load(file = paste0(get("wd", envir = .GlobalEnv),'/rdata.RData' ), envir = user_env)
                 
                 
                # shinyjs::hide(id = "chkbxUsGroup")
                # shinyjs::hide(id = "chkbxIndicatorsGroup")
                # shinyjs::hide(id = "chkbxPeriodGroup")
                 shinyjs::hide(id = "btn_upload")
                # shinyjs::hide(id = "chkbxDatim")
                 break
              }


            }

          },
          #if an error occurs,
          error=function(e) {
            output$instruction <- renderText({  paste0("US Importadas: ", indicatorsToString(vec_us_dados_enviados)) })
            shinyalert("Erro", paste0("Erro durante o envio de dados, Tente novamente", as.character(e)), type = "error")
            message(e)
            break
          }

        )
        message("counter: ", counter )
        message("len(selected_us): length(vec_selected_us)" )
        if(counter==length(vec_selected_us)){
          showNotification("Parabens!!! Todos dados importados com sucesso.",session = getDefaultReactiveDomain(), duration = 5 ,type =  "message" )
          output$instruction <- renderText({  paste0("US Importadas: ", indicatorsToString(vec_us_dados_enviados)) })
          
          
          # Reset Panes after upload
           shinyjs::hide(id = "chkbxPeriodGroup")
           shinyjs::hide(id = "btn_upload")
           output$tbl_integrity_errors <- renderDataTable({
             df <- read_xlsx(path = paste0(get("upload_dir"),'/template_errors.xlsx'))
             datatable( df[0 ,], options = list(paging = TRUE))
           })

          load(file = paste0(get("wd", envir = .GlobalEnv),'/rdata.RData' ), envir = user_env)

          updateAwesomeRadio(getDefaultReactiveDomain(), inputId = "dhis_datasets",label =  "DHIS2 Datasets",
                            choices = mer_datasets_names,
                            selected = ""       )
          updatePickerInput(getDefaultReactiveDomain(), "chkbxUsGroup",
                            label = "U. Sanitarias: ",
                            choices =  list(),
                            options = list(
                              `live-search` = TRUE)
          )

          updateAwesomeCheckboxGroup(getDefaultReactiveDomain(), "chkbxUsGroup",
                                     label = "U. Sanitarias: ",
                                     choices =  character(0)
          )
          updateCheckboxGroupButtons(getDefaultReactiveDomain(),"chkbxIndicatorsGroup",label = "",choices = c("")
          )
          updateActionButtonStyled( getDefaultReactiveDomain(), "btn_checks_before_upload", disabled = TRUE  )
          
  
           updateActionButtonStyled( getDefaultReactiveDomain(), "btn_reset",  disabled = TRUE  )
           output$tbl_integrity_errors <- renderDataTable({
             df <- read_xlsx(path = paste0(get("upload_dir"),'/template_errors.xlsx'))
             datatable( df[0 ,], options = list(paging = TRUE))
           })

           shinyjs::hide(id = "chkbxUsGroup")
           shinyjs::hide(id = "chkbxIndicatorsGroup")
           shinyjs::hide(id = "chkbxPeriodGroup")
           shinyjs::hide(id = "btn_upload")
           shinyjs::hide(id = "chkbxDatim")
           
        } else {
          showNotification("Atencao!!! Ocorreu um erro durante o envio, por favor corrigir",session = getDefaultReactiveDomain(), duration = 5 ,type =  "message" )
          output$instruction <- renderText({  paste0("US Importadas: ", indicatorsToString(vec_us_dados_enviados)) })
          
        }
      }
      

    
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
                             #  extensions = c('Buttons'), 
                               options = list( lengthMenu = list(c(5, 15, -1), c('5', '15', 'All')),
                                               pageLength = 15,
                                               dom = 'Blfrti',
                                               buttons = list(
                                                 list(extend = 'excel', title = NULL),
                                                 'pdf',
                                                 'csv'  ) ) )
                   })
     output$data_tbl_ccs_warnings <- renderDT({
       datatable(env_get(env = user_env,nm = "df_datim" ) ,
                 #extensions = c('Buttons'), 
                 options = list( lengthMenu = list(c(5, 15, -1), c('5', '15', 'All')),
                                 pageLength = 15,
                                 dom = 'Blfrti',
                                 buttons = list(
                                   list(extend = 'excel', title = NULL),
                                   'pdf',
                                   'csv'  ) ) )
     })
     
    submission_date  <- as.character(Sys.Date())
    datim_logs       <- ""
    period           <- input$chkbxDatimPeriodGroup
    selected_province  = input$datim_reproting_provinces
    funding_mechanism = ''
    
    message(period)
    # check selected province
    # select the correct us names and ids based on the selected province
    if(selected_province=="Gaza"){
      hf_names <- env_get(env = .GlobalEnv, nm =  "gaza_us_names_ids_dhis")
      funding_mechanism <-  env_get(env = .GlobalEnv,     nm =  "funding_mechanism_gaza") 
    } else {
      hf_names <- env_get(env = .GlobalEnv, nm =  "maputo_us_names_ids_dhis")
      funding_mechanism <-  env_get(env = .GlobalEnv,     nm =  "funding_mechanism_maputo") 
    }
    
    

    api_dhis_url     <- env_get(env = user_env, nm =  "api_datim_base_url") 
    dataset.id       <- env_get(env = .GlobalEnv, nm =  "dataset_id_mer_datim")
    df_datim         <- env_get(env = user_env,   nm = "df_datim" )
    
    if(length(period)==0){
      shinyalert("Info", "Selecione o Periodo!", type = "info")
      
    } else {
      for (k in 1:length(hf_names) ) {
        i = 0
        us_name <- names(hf_names[k])
        us_id   <-  hf_names[[k]]
        incProgress(1/(length(hf_names)), detail = paste("Processando  o dataset do : ", us_name , " " ))
        # print(us[1])
        df <-  tryCatch(
          {
            message("Getting Datavalues from MER DATIM FORM")
            message("Dataset id: ", dataset.id)
            message("Period: ", period)
            message("Org Unit: ", us_id)
            message("API URL: ", api_dhis_url)
            
            getDatimDataValueSet(api_dhis_url,dataset.id, period, us_id)
          },
          error=function(cond) {
            shinyalert(us_name, cond , type = "info")
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
      
        } 
        else {
          message(us_name, "   - Dataset esta vazio!!!")
          msg        <- paste0(us_name, " - Nao contem dados neste periodo.", '\n')
          datim_logs =     paste(datim_logs, msg, sep = '')
        }
        
      }
      if(nrow(df_datim)>0){
        
        output$txt_datim_logs <-  renderText({ HTML(datim_logs)})
        
        
        #df_datim <- env_get(env = user_env,nm = "df_datim" )
        df_datim$DatimDataElement <- mapply(df_datim$CategoryOptionCombo,df_datim$Dataelement, FUN =  getDhisDataElement)
        df_datim$DatimCategoryOptionCombo <-  mapply(df_datim$CategoryOptionCombo,df_datim$Dataelement, FUN =  getDhisCategoryOptionCombo)
        df_datim$DatimAttributeOptionCombo <- funding_mechanism 
        #df_datim$Period <- sapply( df_datim$Period ,aDjustDhisPeriods)
        df_datim$DatimOrgUnit <- sapply(df_datim$OrgUnit, FUN =  getDhisOrgUnit)
        df_datim$observation <- mapply(df_datim$CategoryOptionCombo,df_datim$Dataelement, FUN =  get99UnusedDataElements)
        
        # Filter 99 observations
        df_datim <- subset(x = df_datim, is.na(observation)  )
        
        df_dataset_datim <- df_datim[,c(7,2,10,8,9,6)]
        names(df_dataset_datim)[1] <- "Dataelement"
        names(df_dataset_datim)[2] <- "Period"
        names(df_dataset_datim)[3] <- "OrgUnit" 
        names(df_dataset_datim)[4] <- "CategoryOptionCombo"
        names(df_dataset_datim)[5] <- "AttributeOptionCombo"
        names(df_dataset_datim)[6] <- "Value"
        
        # Remove zeros from df
        df_dataset_datim <- subset(x = df_dataset_datim, as.integer(df_dataset_datim$Value) > 0 , )
        
       # df_dataset_ccs  <-  df_datim[,c(7,2,10,8,9,6,1,3,4,5)]
        df_dataset_ccs  <-  subset(x = df_datim, as.integer(df_datim$Value) > 0 , )
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
      } 
      else {
        
        
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
                       
                       #
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
