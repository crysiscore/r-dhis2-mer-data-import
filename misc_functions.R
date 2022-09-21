# Required libraries
require(httr)
require(readxl)
require(plyr)

#############################################  Helper functions     ####################################################

#' dhisLogin ->  Login to DHIS2
#' @param dhis2.username DHIS2 username
#' @param  dhis2.password DHIS2 password
#' @param base.url DHIS2 Base URL
#' @examples 
#' source(file = 'credentials.R')
#' api_dhis_base_url <- "https://mail.ccsaude.org.mz:5459/dhis/"
#' dhisLogin(dhis2.username = dhis2.username,dhis2.password = dhis2.password,base.url = api_dhis_base_url )
dhisLogin <- function(dhis2.username, dhis2.password, base.url) {
  url <- paste0(base.url, "api/me")
  r <- GET(url, authenticate(dhis2.username, dhis2.password),timeout(10))
  if (r$status == 200L) {
    print("Logged in successfully!")
  } else {
    print("Could not login")
  }
}


# Generating data value set template - https://docs.dhis2.org/en/develop/using-the-api/dhis-core-version-237/data.html
# To generate a data value set template for a certain data set you can use the /api/dataSets/<id>/dataValueSet resource.
# XML and JSON response formats are supported. 

#' getDhis2DatavalueSetTemplate ->  Retorna um DF que representa o template para importacao de dados no DHIS de um dataset especifico
#' @param dataset.id DHIS2 dataset ID 
#' @param  url.api.dhis.datasets (DHIS API) dataset resource 
#' @return  datavalueset template
#' @examples 
#' source(file = 'credentials.R') # this function needs DHIS Credentials stored on the following variables : dhis2.username & dhis2.password
#' datavalueset_template_dhis2_mer_ct <- getDhis2DatavalueSetTemplate(api_dhis_datasets,dataset_id_mer_ct)
getDhis2DatavalueSetTemplate <- function(url.api.dhis.datasets,dataset.id){
  url_datavalueset_template <- paste0(url.api.dhis.datasets,dataset.id,'/dataValueSet.json')
  http_content <-  content(GET(url_datavalueset_template, authenticate(dhis2.username, dhis2.password),timeout(10)),as = "text",type = 'application/json')
  df_dataset_template =    fromJSON(http_content) %>% as.data.frame
  df_dataset_template = df_dataset_template[,c(1,2,4)]
  names(df_dataset_template)[1] <- 'dataElement'
  names(df_dataset_template)[2] <- 'categoryoptioncombo'
  names(df_dataset_template)[3] <- 'value'
  df_dataset_template
  
}


#' checkIFDataElementExistsOnTemplate ->  Verifica se um dataElement foi mapeiado correctamentamente ie: se existe no dataset especificado
#' @param data.element.id uid do dataelement
#' @param  category.option.combo.id categoryoptioncombo
#' @param datavalueset.template.name nome do datafram do template de importacao para DHIS2
#' @examples 
#'df_dhis2_data_mapping$check <- mapply(checkIFDataElementExistsOnTemplate,df_dhis2_data_mapping$dhisdataelementuid,df_dhis2_data_mapping$dhiscategoryoptioncombouid ,"datavalueset_template_dhis2_mer_ct")
checkIFDataElementExistsOnTemplate  <- function(data.element.id, category.option.combo.id, datavalueset.template.name, indicator.name  ) {
  

  
  df_error_tmp_empty  <- env_get(env = user_env ,nm = "error_log_dhis_import_empty" )
  df_error_tmp        <- env_get(env = user_env,nm = "error_log_dhis_import")
  wd                  <- env_get(env = .GlobalEnv,nm =  "wd" )
  
  #message("Check:  passando aaa 1.1 ")
  tmp <- env_get(env = user_env ,nm =  datavalueset.template.name)
  df <- filter(tmp, dataElement==data.element.id & categoryoptioncombo==category.option.combo.id )
  
  total_rows <- nrow(df)
  if(total_rows==0){
    df_error_tmp_empty$dhisdataelementuid[1] <- data.element.id
    df_error_tmp_empty$dhiscategoryoptioncombouid[1] <- category.option.combo.id
    df_error_tmp_empty$indicator[1] <- indicator.name
    df_error_tmp_empty$error[1] <- 'NOT FOUND'
    df_error_tmp<- rbind.fill(df_error_tmp, df_error_tmp_empty)
    #message("Check:  aaa passando 1.2 ")
    
    saveDataGDrive( df_error_tmp ,file.type='xlsx', file.name ='log_execution_warning', outputDir='logs')
    #writexl::write_xlsx(x = df_error_tmp,path = paste0(wd ,'logs/log_execution_warning.xlsx'),col_names = TRUE,format_headers = TRUE)
    #assign(x = "error_log_dhis_import",value =df_error_tmp, envir = envir )
    env_poke(env = user_env,nm ="error_log_dhis_import",value = df_error_tmp ) # https://adv-r.hadley.nz/environments.html#getting-and-setting-1 - 7.2.5 Getting and setting
    return(FALSE)
  } else if(total_rows==1){
    return(TRUE)
  } else if(total_rows>1){
    df_error_tmp_empty$dhisdataelementuid[1] <- data.element.id
    df_error_tmp_empty$dhiscategoryoptioncombouid[1] <- category.option.combo.id
    df_error_tmp_empty$indicator[1] <- indicator.name
    df_error_tmp_empty$error[1] <- 'DUPLICATED'
    df_error_tmp<- rbind.fill(df_error_tmp, df_error_tmp_empty)
    
    #message("Check: aaa  passando 1.3 ")
    #writexl::write_xlsx(x = df_error_tmp,path = paste0(wd ,'logs/log_execution_warning.xlsx'),col_names = TRUE,format_headers = TRUE)
    saveDataGDrive( df_error_tmp ,file.type='xlsx', file.name ='log_execution_warning', outputDir='logs')
    #assign(x = "error_log_dhis_import",value =df_error_tmp, envir = envir )
    env_poke(env = user_env,nm ="error_log_dhis_import",value = df_error_tmp ) # https://adv-r.hadley.nz/environments.html#getting-and-setting-1 - 7.2.5 Getting and setting
    return('Duplicado')
  }
  
}


#' getDEValueOnExcell ->  Le o valor de uma cell no ficheiro excell
#' @param cell.ref referencia da cell
#' @param  file.to.import location do ficheiro
#' @param sheet.name nome do sheet
#' @examples 
#' val  <- function(cell.ref, file.to.import, sheet.name)
getDEValueOnExcell <- function(cell.ref, file.to.import, sheet.name ){
  
  data_value <- tryCatch({
    #wd <- get("wd", envir = .GlobalEnv)
    wd <- env_get(env = .GlobalEnv, "wd")
    tmp <-   read_xlsx(path = file.to.import,sheet = sheet.name,range = paste0(cell.ref,':',cell.ref),col_names = FALSE)
    if(nrow(tmp)==0){
      warning_msg <- paste0( "Empty excell cell ", cell.ref, ' on  sheetname: ' ,sheet.name)
      
      tmp          <-  env_get(env = user_env, "error_log_dhis_import_empty")
      df_error_tmp <-  env_get(env = user_env, "error_log_dhis_import")
      
      #tmp  <- get('error_log_dhis_import_empty',envir = user.env)
      #df_error_tmp <- get('error_log_dhis_import',envir = user.env)
      
      tmp$sheetname[1] <- sheet.name
      tmp$excellfilename[1] <- path_file(file.to.import)
      tmp$excell_cell_ref[1] <- cell.ref
      tmp$observation[1] <- warning_msg
      tmp$error[1] <- "Warning"
      message("Warning :", warning_msg)
      df_error_tmp  <- rbind.fill(df_error_tmp, tmp)
     # writexl::write_xlsx(x = df_error_tmp,path = paste0(wd ,'logs/log_execution_warning.xlsx'),col_names = TRUE,format_headers = TRUE)
      saveDataGDrive( df_error_tmp ,file.type='xlsx', file.name ='log_execution_warning', outputDir='logs')
      #assign(x = "error_log_dhis_import",value =df_error_tmp, envir = user.env )
      env_poke(env = user_env ,nm =  "error_log_dhis_import",value =  df_error_tmp)
      empty_value <- ""
      return(empty_value)
      
    } else if (nrow(tmp)==1) {
      tmp[[1]]
    }
    
  },
  error = function(cond) {
    error_msg <- paste0( "Error reading from excell: ", cell.ref, 'on sheetname:' ,sheet.name)
    tmp          <-  env_get(env = user_env, "error_log_dhis_import_empty")
    df_error_tmp <-  env_get(env = user_env, "error_log_dhis_import")
    tmp$sheetname[1] <- sheet.name
    tmp$excellfilename[1] <- path_file(file.to.import)
    tmp$excell_cell_ref[1] <- cell.ref
    tmp$error[1] <- error_msg
    message(error_msg)
    df_error_tmp <- rbind.fill(df_error_tmp, tmp)
    #writexl::write_xlsx(x = df_error_tmp,path = paste0(wd, 'logs/log_execution_warning.xlsx'),col_names = TRUE,format_headers = TRUE)
    saveDataGDrive( df_error_tmp ,file.type='xlsx', file.name ='log_execution_warning', outputDir='logs')
    # assign(x = "error_log_dhis_import",value =df_error_tmp, envir = user.env )
    env_poke(env = user_env ,nm =  "error_log_dhis_import",value =  df_error_tmp)
    return(NA)
    
  },
  warning = function(cond) {
    # Choose a return value in case of warning
    message("Stage Warning Check")
    print(as.character(cond))
    
  },
  finally = {
    # NOTE:
    # Here goes everything that should be executed at the end,
    
  })
  
  data_value
}


#' checkDataConsistency ->  Verifica a consistencia dos dados antes de importar para o DHIS2
#' Stage 1 - "Verficar a integridade do ficheiro de importacao"
#' Stage 2 - "Verificar se todos os dataElements do Ficheiro de Mapeamento existem no DHIS2"
#' stage 3 - "Buscar valores para cada indicador: "
#' @param cell.ref referencia da cell
#' @param excell.mapping.template location do ficheiro
#' @param sheet.name nome do sheet
#' @param file.to.import ficheiro de importacao
#' @param vec.indicators indicadores que se deseja importar
#' @param user.env user environment 
#' @param dataset.name nome do formualario dhis 2. ("MER C&T"  = "ct", "MER ATS" = "ats" , "MER SMI" = "smi" , "MER PREVENTION"="prevention", "MER HEALTH SYSTEM"="hs")
#' @examples 
#' is_consistent  <- checkDataConsistency(excell.mapping.template,file.to.import, dataset.name, sheet.name,vec.indicators)
checkDataConsistency <- function(excell.mapping.template, file.to.import,dataset.name, sheet.name, vec.indicators , user.env  ){
 
  withProgress(message = 'Running checks',
               detail = 'This may take a while...', value = 0, {
                 
  #wd <- get("wd",envir = .GlobalEnv)
  wd <- env_get(env = .GlobalEnv, "wd")
  # carregar variaves e dfs para armazenar logs
  # tmp_log_exec <- get('log_execution',envir = user.env)
  tmp_log_exec <- env_get(env = user.env, "log_execution")
  #vec_tmp_dataset_names <-  get('mer_datasets_names',envir = .GlobalEnv)
  vec_tmp_dataset_names <- env_get(env = .GlobalEnv, "mer_datasets_names")
  tmp_log_exec_empty <- tmp_log_exec[1,]
  
  #Indicar a tarefa em execucao: task_check_consistency_1
  tmp_log_exec_empty$Datetime[1] <- substr(x = Sys.time(),start = 1, stop = 22)
  tmp_log_exec_empty$US[1] <- sheet.name
  tmp_log_exec_empty$Dataset[1] <- dataset.name
  #tmp_log_exec_empty$task[1] <- get('task_check_consistency_1',envir = .GlobalEnv)
  tmp_log_exec_empty$task[1] <- env_get(env = .GlobalEnv, "task_check_consistency_1")
  message( "Stage 1: ", env_get(env = .GlobalEnv, "task_check_consistency_1") )

  #assign(x = "log_execution",value =tmp_log_exec_empty, envir = .GlobalEnv )
  incProgress(1/(length(vec.indicators)+ 1), detail = paste("STAGE 1 - ",  env_get(env = .GlobalEnv, "task_check_consistency_1") ))
  # Stage 1: Verficar o a integridade do ficheiro a ser importado
   total_error <- checkImportTamplateIntegrity(file.to.import = file.to.import,dataset.name =dataset.name ,sheet.name =sheet.name, user.env )
   if(total_error > 0) {
     
     for (i  in 1: length(vec.indicators) ) {
       incProgress(1/(length(vec.indicators)+ 1), detail = paste("STAGE II - ", env_get(env = .GlobalEnv, "task_check_consistency_2") ))
       
     }
     
     message('Integrity error')
    return('Integrity error')
   } else {
  # Stage 2: Verificar se todos os dataElements do Ficheiro de Mapeamento existem no DHIS2     
    
     #A tarefa anterior terminou com sucesso
     tmp_log_exec_empty$status[1] <- 'ok'
     tmp_log_exec <- plyr::rbind.fill(tmp_log_exec,tmp_log_exec_empty )
     #assign(x = "log_execution",value =tmp_log_exec, envir = .GlobalEnv )

     
     #Indicar a tarefa em execucao: task_check_consistency_2
     tmp_log_exec_empty$Datetime[1] <- substr(x = Sys.time(),start = 1, stop = 22)
     tmp_log_exec_empty$US[1] <- sheet.name
     tmp_log_exec_empty$Dataset[1] <- dataset.name
     tmp_log_exec_empty$task[1] <-  env_get(env = .GlobalEnv, "task_check_consistency_2")
     tmp_log_exec_empty$status[1] <- 'processando...'
     message( "Stage 2: ",  env_get(env = .GlobalEnv, "task_check_consistency_2"))

     tmp_log_exec <- plyr::rbind.fill(tmp_log_exec,tmp_log_exec_empty )
     #message("Passando I")
     #assign(x = "log_execution",value =tmp_log_exec, envir = user.env )
     env_poke(env = user.env ,nm =  "log_execution",value =  tmp_log_exec)
     #message("Passando I.1")
     #writexl::write_xlsx(x = tmp_log_exec,path = paste0(wd, 'logs/log_execution.xlsx'),col_names = TRUE,format_headers = TRUE)
     saveDataGDrive( tmp_log_exec ,file.type='xlsx', file.name ='log_execution', outputDir='logs')
     datavalueset_template <- getDataValuesetName(dataset.name)
     
     for (indicator in vec.indicators) {
       # GET excell values
       #setwd(wd)
       # Carregar os indicadores do ficheiro do template de Mapeamento  & excluir os dataElements que nao reportamos (observation==99)
       tmp_df <- read_xlsx(path =paste0('mapping/',excell.mapping.template), sheet = indicator , skip = 1 )
       tmp_df <- filter(tmp_df, is.na(observation) )
       tmp_df$check <- ""
       tmp_df$value <- ""
       
       #message("Passando I.2 - " , indicator)
       tmp_df$check  <- mapply(checkIFDataElementExistsOnTemplate,tmp_df$dhisdataelementuid,tmp_df$dhiscategoryoptioncombouid ,datavalueset_template,indicator )
      
       #Indicar a tarefa em execucao : task_check_consistency_3
       tmp_log_exec_empty$Datetime[1] <- substr(x = Sys.time(),start = 1, stop = 22)
       tmp_log_exec_empty$US[1] <- sheet.name
       tmp_log_exec_empty$Dataset[1] <- dataset.name
       tmp_log_exec_empty$task[1] <- paste0( env_get(env = .GlobalEnv, "task_check_consistency_3"), indicator)
       message(  "Stage 3: ",  env_get(env = .GlobalEnv, "task_check_consistency_3"))
       tmp_log_exec <- plyr::rbind.fill(tmp_log_exec,tmp_log_exec_empty )
       #writexl::write_xlsx(x = tmp_log_exec,path = paste0(wd, 'logs/log_execution.xlsx'),col_names = TRUE,format_headers = TRUE)
       saveDataGDrive( tmp_log_exec ,file.type='xlsx', file.name ='log_execution', outputDir='logs')
       env_poke(env = user.env ,nm =  "log_execution",value =  tmp_log_exec)
       #assign(x = "log_execution",value =tmp_log_exec, envir = user.env )
       #message("Passando II")
       #Get excell values
       #setwd('data/')
       tmp_df$value <-  mapply(getDEValueOnExcell,tmp_df$excell_cell_ref, file.to.import, sheet.name=sheet.name )
       
       #assign(paste('DF_',gsub(" ", "", indicator, fixed = TRUE) , sep=''), tmp_df , envir = user.env)
       env_poke(env = user.env ,nm =  paste('DF_',gsub(" ", "", indicator, fixed = TRUE) , sep='') ,value =  tmp_df)
        #A tarefa anterior terminou com sucesso
       tmp_log_exec_empty$status[1] <- 'ok'
       #tmp_log_exec <- plyr::rbind.fill(tmp_log_exec,tmp_log_exec_empty )
       #writexl::write_xlsx(x = tmp_log_exec,path = paste0(wd, 'logs/log_execution.xlsx'),col_names = TRUE,format_headers = TRUE)
       incProgress(1/(length(vec.indicators)+ 1), detail = paste("STAGE III - Processando  o indicador: ", indicator , " " ))
       #message("Passando III")
       }
    

     #assign(x = "log_execution",value =tmp_log_exec, envir = user.env )
     env_poke(env = user.env ,nm =  "log_execution",value =  tmp_log_exec)
     return("No errors")
     
   }
     


}) # end with progress


}


#' checkImportTamplateIntegrity ->  Verifica se o template/sheet que contem dados a ser importado esta devidamente formatado
#' @param cell.ref referencia da cell
#' @param  excell.mapping.template location do ficheiro
#' @param sheet.name nome do sheet
#' @examples 
#' erros  <- checkImportTamplateIntegrity(file.to.import, dataset.name, sheet.name)
checkImportTamplateIntegrity  <- function(file.to.import,dataset.name,sheet.name , user.env ){
  
  #wd <- env_get(env = .GlobalEnv, "wd")
  #setwd(wd)
  df_checks <- read_xlsx(path ='mapping/dhis_mer_checks.xlsx', sheet = 1 ,col_names = TRUE  )
  
  df_cells_to_ckeck  <- filter(df_checks, Dataset ==dataset.name)
  df_cells_to_ckeck$value_on_template <-""
  df_cells_to_ckeck$error_message <-""
  total_errors <-0
  
  for (index  in 1:nrow(df_cells_to_ckeck)) {
    
      cell_ref <- df_cells_to_ckeck$Cell[index]
      cell_value <- df_cells_to_ckeck$Value[index]
      
      value_on_template <- getDEValueOnExcell( cell_ref ,file.to.import = file.to.import,sheet.name = sheet.name   )
      if(trimws(value_on_template) != cell_value){
        #TODO escrever os erros num ficheiro de texto para posterior apresentacao
        error_msg <- paste0(Sys.Date()," TEMPLATE ERROR ('",dataset.name,"|",sheet.name,"'): O ficheiro de importacao nao esta consistente, a cellula: ",cell_ref, " Devia ter o valor: '", cell_value,"'")
        message(error_msg )
        total_errors <- total_errors +1
        df_cells_to_ckeck$value_on_template[index] <-  value_on_template
        df_cells_to_ckeck$error_message[index]     <-  error_msg
        
      } else {
        df_cells_to_ckeck$value_on_template[index] <-  'ok'
        df_cells_to_ckeck$error_message[index]     <-  'ok'
        message(Sys.Date()," Cell: ",cell_ref ,"  value: '", value_on_template ,"' is ok. Reading next value ... " )
      }
    
  }
  #Write error 
  if(total_errors> 0){
   # writexl::write_xlsx(x = df_cells_to_ckeck,path = 'errors/template_errors.xlsx')
    saveDataGDrive( df_cells_to_ckeck ,file.type='xlsx', file.name ='template_errors', outputDir='errors')
  }
  return(total_errors)
  
}


#' getTemplateDatasetName ->  Retorna o nome do template de mapeamento correspondente ao nome do dataset
#' @param dataset.name nome do dataset c("MER C&T"  = "ct", "MER ATS" = "ats" , "MER SMI" = "smi" , "MER PREVENTION"="prevention", "MER HEALTH SYSTEM"="hs")
#' @examples 
#' mer_template  <- getTemplateDatasetName(dataset.name)
getTemplateDatasetName <- function(dataset.name) {
  
  template_name <- ""
  if(dataset.name=='MER C&T'){
    datavalueset_template <-"MER CARE & TREATMENT.xlsx"
  } else if(dataset.name=='MER ATS'){
    datavalueset_template <- "MER ATS.xlsx"
  } else if(dataset.name=='MER SMI'){
    datavalueset_template <- "MER SMI.xlsx"
  } else if(dataset.name=='MER PREVENTION'){
    datavalueset_template <- "MER PREVENTION.xlsx"
  }else if(dataset.name=='MER HEALTH SYSTEM'){
    datavalueset_template <- "MER HEALTH SYSTEMS.xlsx"
  } else {
    return("unkown")
  }
  
  return(datavalueset_template)
}


#' merIndicatorsToJson ->  Transforma para o formato json os datagframes gerados apos o correr os checks do ficheiro de importacao
#'                        o json sera usado para enviar os dados para o DHIS2
#' @param dataset.id id do dataset no DHIS2
#' @param  complete.date data de submissao
#' @param  period periodo de submissao
#' @param  org.unit id da US
#' @param  vec.indicators indicadores a importar
#' @example 
#' string_json  <- merIndicatorsToJson(dataset.id, complete.date, period , org.unit, vec.indicators)
merIndicatorsToJson <- function(dataset.id, complete.date, period , org.unit, vec.indicators, user.env){
  
  dataSetID    <- dataset.id
  completeDate <- complete.date
  period       <- period
  orgUnit      <- org.unit
  df_all_indicators <- NULL

  json_header <- paste0( "\"dataSet\":\"",dataSetID, "\" ," ,
                         "\"completeDate\":\"",completeDate , "\" ," ,
                         "\"period\":\"", period , "\" ," ,
                         "\"orgUnit\":\"",orgUnit,"\" , " ,  
                         "\"dataValues\":" ) 
  
  # junta os df de todos indicadores processados
  for (indicator in  vec.indicators) {
    
    #df               <- get(paste('DF_',gsub(" ", "", indicator, fixed = TRUE) , sep=''), envir = user.env)
    df                <- env_get(env =user.env ,nm =  paste('DF_',gsub(" ", "", indicator, fixed = TRUE) , sep=''))
    
    if(nrow(df) > 0){
      
      df_all_indicators <- plyr::rbind.fill(df_all_indicators, df)
    }
    
    
  }
  
  df_all_indicators <- df_all_indicators[, c("dhisdataelementuid","dhiscategoryoptioncombouid","value")]
  df_all_indicators <- subset(df_all_indicators, !(is.na(value) | value =="")) # remover dataelements sem dados
  names(df_all_indicators)[1] <-  "dataElement"
  names(df_all_indicators)[2] <- "categoryOptionCombo"
  names(df_all_indicators)[3] <- "value"
  
  # converte os valores para json
  json_data_values <- as.character(toJSON(x = df_all_indicators , dataframe = 'rows'))
  
  #Unir com o header para formar o payload
  json <- paste0( "{ ", json_header, json_data_values, "  }")
  
  json
  
}


#' apiDhisSendDataValues ->  Envia o json para o endpoint '/api/33/dataValueSets' (https://docs.dhis2.org/en/develop/using-the-api/dhis-core-version-237/data.html)
#'                        
#' @param json  string json    
#' @example
#' status <- apiDhisSendDataValues
apiDhisSendDataValues <- function(json){
  withProgress(message = 'Enviando Dados para o DHIS',
               detail = 'This may take a while...', value = 0, {
                 
  # url da API
  base.url <- paste0(get('api_dhis_base_url',envir = .GlobalEnv),get("api_dhis_datasetvalues_endpoint",envir = .GlobalEnv))
  
  incProgress(1/2, detail = paste("This may take a while..." ))
  # Post data to DHIS2
  status <- POST(url = base.url,
                 body = json, config=authenticate(get("dhis2.username",envir =  .GlobalEnv), get("dhis2.password",envir =  .GlobalEnv)),
                 add_headers("Content-Type"="application/json") )
  
  incProgress(1/2, detail = paste("This may take a while..." ))
  
               })
  # The reponse from server will be an object with the following structure
  # Response [http://192.168.1.10:5400/api/33/dataValueSets]
  # Date: 2022-09-01 10:17
  # Status: 200
  # Content-Type: application/json;charset=UTF-8
  # Size: 861 B
  return(status)
  
}


#' saveLogUploadedIndicators ->  guarda os datasets dos indicadores enviados ao dhis
#' @param  vec.indicators indicadores a importar
#' @param upload.date  data do upload   
#' @param period  periodo
#' @param df.warnings df com campos vazios
#' @examples
#' saveLogUploadedIndicators(us.name = us_name, vec.indicators = vec_indicators,upload.date =submission_date,period =period , df.warnings = df_warnings)
saveLogUploadedIndicators <- function(us.name, vec.indicators, upload.date,period,df.warnings){
  


  upload_dir <- "uploads"
  
  #setwd(upload_dir)
  
  # check if sub directory exists 
 # if (drop_exists(path = paste0(upload_dir,'/',upload.date), dtoken = env_get(env = .GlobalEnv,nm = 'token'))){
  if (  upload.date %in%  as.vector(drive_ls(upload_dir) %>%  select('name') )[[1]]){
  
 
    # change to dir
    curr_upload_dir <- paste0(upload_dir,'/' , upload.date)
    #setwd(curr_upload_dir)
    
    # check  if us dir  is created
    #if (drop_exists(path = paste0(curr_upload_dir,'/',us.name), dtoken = env_get(env = .GlobalEnv,nm = 'token'))){
    if (  us.name %in%  as.vector(drive_ls(curr_upload_dir) %>%  select('name') )[[1]]){
       tmp_wd <- paste0(curr_upload_dir,'/',us.name)

     # if(drop_exists(path = paste0(tmp_wd,'/',period), dtoken = env_get(env = .GlobalEnv,nm = 'token'))){
       if (  period %in%  as.vector(drive_ls(tmp_wd) %>%  select('name') )[[1]]){
        path_period <-  paste0(tmp_wd,'/',period)
        # set  wd
        #TODO save files here
        for (indicator in vec.indicators) {
          
          #tmp_df <- get( paste('DF_',gsub(" ", "", indicator, fixed = TRUE) , sep=''), envir = user.env )
          tmp_df <- env_get(env = user_env , paste('DF_',gsub(" ", "", indicator, fixed = TRUE) , sep=''))
          
          #writexl::write_xlsx(x = tmp_df,path = paste0('DF_',gsub(" ", "", indicator, fixed = TRUE) ,".xlsx" ))
          saveDataGDrive( tmp_df ,file.type='xlsx', file.name =paste0('DF_',gsub(" ", "", indicator, fixed = TRUE)), outputDir=path_period)
        }
        #writexl::write_xlsx(x =df.warnings,path ='empty_cells_warning.xlsx' ,col_names = TRUE,format_headers = TRUE)
        saveDataGDrive( df.warnings ,file.type='xlsx', file.name ='empty_cells_warning', outputDir=path_period)
      } else {
         
        # create dir
        tmp_dir <- paste0(tmp_wd,'/',period )
        drive_mkdir(tmp_dir )
        
        # set as wd
        #TODO save files here
        for (indicator in vec.indicators) {
          
          #tmp_df <- get( paste('DF_',gsub(" ", "", indicator, fixed = TRUE) , sep=''), envir = user.env )
          tmp_df <- env_get(env = user_env , paste('DF_',gsub(" ", "", indicator, fixed = TRUE) , sep=''))
          #writexl::write_xlsx(x = tmp_df,path = paste0('DF_',gsub(" ", "", indicator, fixed = TRUE) ,".xlsx" ))
          saveDataGDrive( tmp_df ,file.type='xlsx', file.name =paste0('DF_',gsub(" ", "", indicator, fixed = TRUE)), outputDir=tmp_dir)
        }
        #writexl::write_xlsx(x =df.warnings,path ='empty_cells_warning.xlsx' ,col_names = TRUE,format_headers = TRUE)
        saveDataGDrive( df.warnings ,file.type='xlsx', file.name ='empty_cells_warning', outputDir=tmp_dir)
      }
      
      
      
    } 
    else {
        
      tmp_path <- paste0(curr_upload_dir, '/', us.name) # create us dir
      drive_mkdir(tmp_path)

      tmp_dir <- paste0(tmp_path,'/',period )           # Then creates period dir inside us dir
      drive_mkdir(tmp_dir  )
     
      #TODO Save files here
      for (indicator in vec.indicators) {
        
        #tmp_df <- get( paste('DF_',gsub(" ", "", indicator, fixed = TRUE) , sep=''), envir = user.env )
        tmp_df <- env_get(env = user_env , paste('DF_',gsub(" ", "", indicator, fixed = TRUE) , sep=''))
        
        #writexl::write_xlsx(x = tmp_df,path = paste0('DF_',gsub(" ", "", indicator, fixed = TRUE) ,".xlsx" ))
        saveDataGDrive( tmp_df ,file.type='xlsx', file.name =paste0('DF_',gsub(" ", "", indicator, fixed = TRUE)), outputDir=tmp_dir)
      }
      #writexl::write_xlsx(x =df.warnings,path ='empty_cells_warning.xlsx' ,col_names = TRUE,format_headers = TRUE)
      saveDataGDrive( df.warnings ,file.type='xlsx', file.name ='empty_cells_warning', outputDir=tmp_dir)
      }

    
  } 
  else {
    
    # create a new sub directory inside
    # the main path
    drive_mkdir(file.path(upload_dir, upload.date) )
    tmp_dir <- file.path(upload_dir, upload.date) 

    tmp_path_us <-  file.path(tmp_dir,  us.name) # create us dir
    drive_mkdir(file.path(tmp_path_us))
 
    tmp_dir_period <- file.path(tmp_path_us, period )           # Then creates period dir inside us dir
    drive_mkdir(tmp_dir_period )

    # TODO Save files here
    for (indicator in vec.indicators) {
      
      #tmp_df <- get( paste('DF_',gsub(" ", "", indicator, fixed = TRUE) , sep=''), )
      tmp_df <- env_get(env = user_env , paste('DF_',gsub(" ", "", indicator, fixed = TRUE) , sep=''))
      saveDataGDrive( tmp_df ,file.type='xlsx', file.name =paste0('DF_',gsub(" ", "", indicator, fixed = TRUE)), outputDir=tmp_dir_period)
      
    }
    #writexl::write_xlsx(x =df.warnings,path ='empty_cells_warning.xlsx' ,col_names = TRUE,format_headers = TRUE)
    saveDataGDrive( df.warnings ,file.type='xlsx', file.name ='empty_cells_warning', outputDir=tmp_dir_period)
  }
  
  
}


getDataValuesetName <- function(dataset.name) {
  
  datavalueset_template <- ""
  if(dataset.name=='MER C&T'){
    datavalueset_template <-"datavalueset_template_dhis2_mer_ct"
  } else if(dataset.name=='MER ATS'){
    datavalueset_template <- "datavalueset_template_dhis2_mer_ats"
  } else if(dataset.name=='MER SMI'){
    datavalueset_template <- "datavalueset_template_dhis2_mer_smi"
  } else if(dataset.name=='MER PREVENTION'){
    datavalueset_template <- "datavalueset_template_dhis2_mer_prevention"
  }else if(dataset.name=='MER HEALTH SYSTEM'){
    datavalueset_template <- "datavalueset_template_dhis2_mer_hs"
  } else {
    return("unkown")
  }
  
  return(datavalueset_template)
}

getUsNameFromSheetNames <-function(vector){
  
  vec <- c()
  for (item in vector) {
    
    vec <- c(vec, strsplit(item, "_")[[1]][3])
  }
  vec
}

getDataSetDataElements <- function(base.url, dataset.id) {
  
  url <-
    paste0(
      base.url,
      paste0(
        "api/dataSets/",
        dataset.id,
        "?fields=id,name,dataSetElements[dataElement[id,name,shortName]]"
      )
    )
  
  
  # Get  data
  r2 <- content(GET(url, authenticate(dhis2.username, dhis2.password)), as = "text",type = 'application/json')
  if(nchar(r2)>1000){
    tmp =fromJSON(r2) %>% as.data.frame
    return(tmp)
  }
  tmp
  
}


#checkDataConsistency(excell.mapping.template, file.to.import,dataset.name, sheet.name, vec.indicators )


saveDataGDrive <- function(data ,file.type, file.name , outputDir) {

  # Create a unique file name
  
  temp_file_name <- ""
  # Write the data to a temporary file locally
  filePath <- ""
  if(file.type=="xlsx"){
    temp_file_name <- file.name
    filePath <- file.path(tempdir(), paste0( temp_file_name,".xlsx"))
    writexl::write_xlsx(x=data,path =  filePath, col_names =  TRUE, format_headers  = TRUE)
    
  } else if (file.type=="csv"){
    
    
  } 

  # Upload the file to Dropbox
  # drop_upload(dtoken = env_get(env = .GlobalEnv, nm = "token"),file = filePath, path = outputDir , mode = "overwrite")
  drive_upload( media =filePath  ,path = outputDir , name = file.name ,type = "xlsx" , overwrite = TRUE)
}



#' gdrive_read_xls
#'
#' A lightweight wrapper around \code{read.xls} to read csv files from Dropbox into memory
#' @param file Name of file with full path relative to Dropbox root
#' @param  dest A temporary directory where a xls file is downloaded before being read into memory
#' @param  ... Additional arguments into \code{read.xls}
#' @template token
#' @export
#' @examples \dontrun{
#' write_xlslx(iris, file = "iris.xlsx")
#' drop_upload("iris.csv")
#' # Now let's read this back into an R session
#' new_iris <- gdrive_read_xls("iris.xlsx")
#'}
gdrive_read_xls <- function(file, dest = tempdir() ) {
  localfile = paste0(dest, "/", basename(file))
  drive_download(file=file, path = localfile, overwrite = TRUE)
  readxl::read_xlsx(path = localfile, col_names = TRUE)
}

