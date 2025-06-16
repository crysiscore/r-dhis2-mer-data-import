# Required libraries
require(httr)
require(readxl)
require(plyr)
require(dplyr)
require(jsonlite)

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
  r <- GET(url, authenticate(dhis2.username, dhis2.password),timeout(35))
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
  http_content <-  content(GET(url_datavalueset_template, authenticate(dhis2.username, dhis2.password),timeout(35)),as = "text",type = 'application/json')
  df_dataset_template =    fromJSON(http_content) %>% as.data.frame
  df_dataset_template = df_dataset_template[,c(1,2,4)]
  names(df_dataset_template)[1] <- 'dataElement'
  names(df_dataset_template)[2] <- 'categoryoptioncombo'
  #names(df_dataset_template)[1] <- 'categoryoptioncombo'
  #names(df_dataset_template)[2] <- 'dataElement'
  names(df_dataset_template)[3] <- 'value'
  df_dataset_template
  
}


#' checkIFDataElementExistsOnTemplate ->  Verifica se um dataElement foi mapeiado correctamentamente ie: se existe no dataset especificado
#' @param data.element.id uid do dataelement
#' @param  category.option.combo.id categoryoptioncombo
#' @param datavalueset.template.name nome do datafram do template de importacao para DHIS2
#' @examples 
#'df_dhis2_data_mapping$check <- mapply(checkIFDataElementExistsOnTemplate,df_dhis2_data_mapping$dhisdataelementuid,df_dhis2_data_mapping$dhiscategoryoptioncombouid ,"datavalueset_template_dhis2_mer_ct")
checkIFDataElementExistsOnTemplate  <- function(data.element.id, category.option.combo.id, datavalueset.template.name, indicator.name, excell.cell.ref, sheet.name  ) {
  

  
  df_error_tmp_empty  <- env_get(env = user_env ,nm = "error_log_dhis_import_empty" )
  df_error_tmp        <- env_get(env = user_env,nm = "error_log_dhis_import")
  wd                  <- env_get(env = .GlobalEnv,nm =  "wd" )
  
 # message("Check:  passando aaa 1.1")
  tmp <- env_get(env = user_env , nm =  datavalueset.template.name)
 # message("Rows: " ,nrows(tmp))

  df <- filter(tmp, dataElement==data.element.id & categoryoptioncombo==category.option.combo.id )
  
  total_rows <- nrow(df)

  if(total_rows==0){

    df_error_tmp_empty$dhisdataelementuid[1] <- data.element.id
    df_error_tmp_empty$dhiscategoryoptioncombouid[1] <- category.option.combo.id
    df_error_tmp_empty$indicator[1] <- indicator.name
    df_error_tmp_empty$error[1] <- 'NOT FOUND'

    df_error_tmp_empty$sheetname[1] <- sheet.name
    df_error_tmp_empty$excell_cell_ref[1] <- excell.cell.ref
    df_error_tmp_empty$observation[1]<-  paste0( "DE nao encontrado: CELL", excell.cell.ref, ' on  sheetname: ' ,sheet.name)
    df_error_tmp<- rbind.fill(df_error_tmp, df_error_tmp_empty)
    
    #browser()
    #message("Check:  aaa passando 1.2 ")
    writexl::write_xlsx(x = df_error_tmp,path = paste0(wd ,'/logs/log_execution_warning.xlsx'),col_names = TRUE,format_headers = TRUE)
    #assign(x = "error_log_dhis_import",value =df_error_tmp, user.envir = user.envir )
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
    writexl::write_xlsx(x = df_error_tmp,path = paste0(wd ,'/logs/log_execution_warning.xlsx'),col_names = TRUE,format_headers = TRUE)
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
getDEValueOnExcell <- function(cell.ref, file.to.import, sheet.name,data.element.id,category.option.combo.id, indicator.name ){
  
  data_value <- tryCatch({
    #wd <- get("wd", envir = .GlobalEnv)
    wd <- env_get(env = .GlobalEnv, "wd")
    tmp <-   read_xlsx(path = file.to.import,sheet = sheet.name,range = paste0(cell.ref,':',cell.ref),col_names = FALSE)
    if(nrow(tmp)==0){
      warning_msg <- paste0( "Celula Vazia ", cell.ref, ' on  sheetname: ' ,sheet.name)
      
      tmp          <-  env_get(env = user_env, "error_log_dhis_import_empty")
      df_error_tmp <-  env_get(env = user_env, "error_log_dhis_import")
      
      #tmp  <- get('error_log_dhis_import_empty',envir = user.env)
      #df_error_tmp <- get('error_log_dhis_import',envir = user.env)
      tmp$dhisdataelementuid[1] <- data.element.id
      tmp$dhiscategoryoptioncombouid[1] <- category.option.combo.id
      tmp$indicator[1] <- indicator.name
      
      tmp$sheetname[1] <- sheet.name
      tmp$excellfilename[1] <- path_file(file.to.import)
      tmp$excell_cell_ref[1] <- cell.ref
      tmp$observation[1] <- warning_msg
      tmp$error[1] <- "Warning"
      message("Warning :", warning_msg)
      df_error_tmp  <- rbind.fill(df_error_tmp, tmp)
      #browser()
      writexl::write_xlsx(x = df_error_tmp,path = paste0(wd ,'/logs/log_execution_warning.xlsx'),col_names = TRUE,format_headers = TRUE)
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
    
    tmp$dhisdataelementuid[1] <- data.element.id
    tmp$dhiscategoryoptioncombouid[1] <- category.option.combo.id
    tmp$indicator[1] <- indicator.name
    
    tmp$sheetname[1] <- sheet.name
    tmp$excellfilename[1] <- path_file(file.to.import)
    tmp$excell_cell_ref[1] <- cell.ref
    tmp$error[1] <- error_msg
    message(error_msg)
    df_error_tmp <- rbind.fill(df_error_tmp, tmp)
    writexl::write_xlsx(x = df_error_tmp,path = paste0(wd, '/logs/log_execution_warning.xlsx'),col_names = TRUE,format_headers = TRUE)
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
checkDataConsistency <- function(excell.mapping.template, file.to.import,dataset.name, sheet.name, vec.indicators , user.env, us.name , is.datim.upload ){
 

  withProgress(message = us.name,
               detail = 'This may take a while...', value = 0, {
                 

  wd <- env_get(env = .GlobalEnv, "wd")
  # carregar variaves e dfs para armazenar logs

  tmp_log_exec <- env_get(env = user.env, "log_execution")
  vec_tmp_dataset_names <- env_get(env = .GlobalEnv, "mer_datasets_names")
  tmp_log_exec_empty <- tmp_log_exec[1,]
  
  #Indicar a tarefa em execucao: task_check_consistency_1
  tmp_log_exec_empty$Datetime[1] <- substr(x = Sys.time(),start = 1, stop = 22)
  tmp_log_exec_empty$US[1] <- sheet.name
  tmp_log_exec_empty$Dataset[1] <- dataset.name

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


     env_poke(env = user.env ,nm =  "log_execution",value =  tmp_log_exec)

     writexl::write_xlsx(x = tmp_log_exec,path = paste0(wd, '/logs/log_execution.xlsx'),col_names = TRUE,format_headers = TRUE)

      datavalueset_template <-  'template_dhis_ccs_forms'
      
      # verifica os dataelements usando o template do formulario datim
      if(is.datim.upload){
        datavalueset_template <-  'template_dhis2_datim'
        
      }
      
     for (indicator in vec.indicators) {
       # GET excell values
       setwd(wd)
       # Carregar os indicadores do ficheiro do template de Mapeamento  & excluir os dataElements que nao reportamos (observation==99)
 
        if(is.datim.upload){
         tmp_df <- read_xlsx(path =paste0('mapping/Datim/',excell.mapping.template), sheet = indicator , skip = 1 )
         
        } else {
          tmp_df <- read_xlsx(path =paste0('mapping/DHIS2/',excell.mapping.template), sheet = indicator , skip = 1 )
       }

       tmp_df <- filter(tmp_df, is.na(observation) )
       tmp_df$check <- ""
       tmp_df$value <- ""
       
       #Message("Iniciando 2.2 - " , indicator)
       tmp_df$check  <- mapply(checkIFDataElementExistsOnTemplate,tmp_df$dhisdataelementuid,tmp_df$dhiscategoryoptioncombouid ,datavalueset_template ,indicator , tmp_df$excell_cell_ref, sheet.name=sheet.name )
       #message("Passando 2.2 - " , indicator)
       #Indicar a tarefa em execucao : task_check_consistency_3
       tmp_log_exec_empty$Datetime[1] <- substr(x = Sys.time(),start = 1, stop = 22)
       tmp_log_exec_empty$US[1] <- sheet.name
       tmp_log_exec_empty$Dataset[1] <- dataset.name
       tmp_log_exec_empty$task[1] <- paste0( env_get(env = .GlobalEnv, "task_check_consistency_3"), indicator)
       message(  "Stage 3: ",  env_get(env = .GlobalEnv, "task_check_consistency_3"))
       tmp_log_exec <- plyr::rbind.fill(tmp_log_exec,tmp_log_exec_empty )
       writexl::write_xlsx(x = tmp_log_exec,path = paste0(wd, '/logs/log_execution.xlsx'),col_names = TRUE,format_headers = TRUE)
       env_poke(env = user.env ,nm =  "log_execution",value =  tmp_log_exec)
       #assign(x = "log_execution",value =tmp_log_exec, envir = user.env )
       #message("Passando II")
       #Get excell values
       # setwd('data/')
       
       # Remove rows with 99 (not used) on observations
       tmp_df <- subset(tmp_df, !observation %in% c(99) ,)
       tmp_df$value <-  mapply(getDEValueOnExcell,tmp_df$excell_cell_ref, file.to.import, sheet.name=sheet.name , tmp_df$dhisdataelementuid, tmp_df$dhiscategoryoptioncombouid, indicator )
       
       #assign(paste('DF_',gsub(" ", "", indicator, fixed = TRUE) , sep=''), tmp_df , envir = user.env)
       env_poke(env = user.env ,nm =  paste(us.name,'_DF_',gsub(" ", "", indicator, fixed = TRUE) , sep='') ,value =  tmp_df)
        #A tarefa anterior terminou com sucesso
       tmp_log_exec_empty$status[1] <- 'ok'

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
  
  wd <- env_get(env = .GlobalEnv, "wd")
  setwd(wd)
  df_checks <- read_xlsx(path ='mapping/dhis_mer_checks.xlsx', sheet = 1 ,col_names = TRUE  )
  
  df_cells_to_ckeck  <- filter(df_checks, Dataset ==dataset.name)
  df_cells_to_ckeck$value_on_template <-""
  df_cells_to_ckeck$error_message <-""
  total_errors <-0
  
  for (index  in 1:nrow(df_cells_to_ckeck)) {
    
      cell_ref <- df_cells_to_ckeck$Cell[index]
      cell_value <- df_cells_to_ckeck$Value[index]
      
      value_on_template <- getDEValueOnExcell( cell_ref ,file.to.import = file.to.import,sheet.name = sheet.name   )
      if(trimws(value_on_template) != trimws(cell_value)){
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
    writexl::write_xlsx(x = df_cells_to_ckeck,path = paste0(get("upload_dir"),'/template_errors.xlsx'))
  }
  return(total_errors)
  
}


#' getTemplateDatasetName ->  Retorna o nome do template de mapeamento correspondente ao nome do dataset
#' @param dataset.name nome do dataset c("MER C&T"  = "ct", "MER ATS" = "ats" , "MER SMI" = "smi" , "MER PREVENTION"="prevention", "MER HEALTH SYSTEM"="hs")
#' @examples 
#' mer_template  <- getTemplateDatasetName(dataset.name)
getTemplateDatasetName <- function(dataset.name) {  #TODO Change this code to read directly from an excell file
  
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
    datavalueset_template <- "MER HEALTH SYSTEM.xlsx"
  }else if(dataset.name=='MER ATS COMMUNITY'){
    datavalueset_template <- "MER ATS COMMUNITY.xlsx"
  }else if(dataset.name=='MER HEALTH SYSTEM'){
    datavalueset_template <- "MER HEALTH SYSTEM.xlsx"
  }else if(dataset.name=='NON MER - MDS e Avaliacao de Retencao'){
    datavalueset_template <- "NON MER MAPPING MDS.xlsx"
  } else {
    return("unkown")
  }
  
  return(datavalueset_template)
}


#' merIndicatorsToJson ->  Transforma para o formato json os dataframes gerados apos o correr os checks do ficheiro de importacao
#'                        o json sera usado para enviar os dados para o DHIS2
#' @param dataset.id id do dataset no DHIS2
#' @param  complete.date data de submissao
#' @param  period periodo de submissao
#' @param  org.unit id da US
#' @param  vec.indicators indicadores a importar
#' @example 
#' string_json  <- merIndicatorsToJson(dataset.id, complete.date, period , org.unit, vec.indicators)
merIndicatorsToJson <- function(dataset.id, complete.date, period , org.unit, vec.indicators, user.env, org.unit.name){
  
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
    df                <- env_get(env =user.env ,nm =  paste(org.unit.name,'_DF_',gsub(" ", "", indicator, fixed = TRUE) , sep=''))
    
    if(nrow(df) > 0){
      
      df_all_indicators <- plyr::rbind.fill(df_all_indicators, df)
    }
    
    
  }
  
  df_all_indicators <- df_all_indicators[, c("dhisdataelementuid","dhiscategoryoptioncombouid","value")]
  df_all_indicators <- subset(df_all_indicators, !(is.na(value) | value =="")) # remover dataelements sem dados
  names(df_all_indicators)[1] <-  "dataElement"
  names(df_all_indicators)[2] <-  "categoryOptionCombo"
  names(df_all_indicators)[3] <-  "value"
  
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
apiDhisSendDataValues <- function(json , dhis.conf, us.name){
  withProgress(message = paste0(us.name, ': Enviando Dados para o DHIS'),
               detail = 'This may take a while...', value = 0, {
                 
  # url da API
  # 2 - DHIS2 API ENDPOINTS : https://docs.dhis2.org/en/develop/using-the-api/dhis-core-version-237/data.html 
                 
  base.url <- paste0(dhis.conf['e-analisys'][[1]][1] , dhis.conf['e-analisys'][[1]][3])
  
  incProgress(1/2, detail = paste("This may take a while..." ))
  # Post data to DHIS2
  status <- POST(url = base.url,
                 body = json, config=authenticate(get("dhis2.username",envir =  .GlobalEnv ,timeout(50) ) , get("dhis2.password",envir =  .GlobalEnv)),
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

#' apiDatimSendDataValues ->  Envia dados  json para o endpoint '/api/33/dataValueSets' (https://docs.dhis2.org/en/develop/using-the-api/dhis-core-version-237/data.html)
#' No formulario do DATIM
#'                        
#' @param json  string json    
#' @example
#' status <- apiDatimSendDataValues
apiDatimSendDataValues <- function(json , dhis.conf, us.name){
  
  withProgress(message = paste0(us.name, ': Enviando Dados para o DHIS'),
               detail = 'This may take a while...', value = 0, {
                 
                 # url da API
                 # 2 - DHIS2 API ENDPOINTS : https://docs.dhis2.org/en/develop/using-the-api/dhis-core-version-237/data.html 

                 base.url <- paste0(dhis.conf['e-analisys'][[1]][1] , dhis.conf['e-analisys'][[1]][3])
                 incProgress(1/2, detail = paste("This may take a while..." ))
                 # Post data to DHIS2
                 status <- POST(url = base.url,
                                body = json, 
                                config=authenticate(get("dhis2.username",envir =  .GlobalEnv  ) , get("dhis2.password",envir =  .GlobalEnv)),
                                add_headers("Content-Type"="application/json"),
                                timeout(35))
                 
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
#' @param  is.datim.form for datim form (all indicators in on form)
#' @examples
#' saveLogUploadedIndicators(us.name = us_name, vec.indicators = vec_indicators,upload.date =submission_date,period =period , df.warnings = df_warnings, envir)
saveLogUploadedIndicators <- function(us.name, vec.indicators, upload.date,period,df.warnings , user.env, is.datim.form,org.unit.name){
  
   upload_directory <- ""
  
  if(is.datim.form==TRUE){
    upload_directory <- paste0(get("upload_dir"),"/", "datim" , "/")
  } else {
    
    upload_directory <- paste0(get("upload_dir"),"/", "mensal", "/")
  }

  setwd(upload_directory)
  message(upload_directory)
  # check if sub directory exists 
  if (file.exists(upload.date)){
    
    # change to dir
    curr_upload_dir <- paste0(upload_directory, upload.date)
    setwd(curr_upload_dir)
    
    # check  if us dir  is created
    if (file.exists(us.name)){
      
       tmp_wd <- paste0(curr_upload_dir,'/',us.name)
       setwd(tmp_wd)
      if(file.exists(period )){
        setwd(period)
        # save files here
        for (indicator in vec.indicators) {
          
          #tmp_df <- get( paste('DF_',gsub(" ", "", indicator, fixed = TRUE) , sep=''), envir = user.env )
          tmp_df <- env_get(env = user.env , paste(org.unit.name,'_DF_',gsub(" ", "", indicator, fixed = TRUE) , sep=''))
          
          writexl::write_xlsx(x = tmp_df,path = paste0('DF_',gsub(" ", "", indicator, fixed = TRUE) ,".xlsx" ))
          
        }
        writexl::write_xlsx(x =df.warnings,path ='empty_cells_warning.xlsx' ,col_names = TRUE,format_headers = TRUE)
        
      } else {
         
        # create dir
        tmp_dir <- paste0(tmp_wd,'/',period )
        dir.create(file.path(tmp_dir))
        setwd(tmp_dir)
    
        # save files here
        for (indicator in vec.indicators) {
          
          #tmp_df <- get( paste(org.unit.name,'_DF_',gsub(" ", "", indicator, fixed = TRUE) , sep=''), envir = user.env )
          tmp_df <- env_get(env = user.env , paste(org.unit.name,'_DF_',gsub(" ", "", indicator, fixed = TRUE) , sep=''))
          writexl::write_xlsx(x = tmp_df,path = paste0('DF_',gsub(" ", "", indicator, fixed = TRUE) ,".xlsx" ))
          
        }
        writexl::write_xlsx(x =df.warnings,path ='empty_cells_warning.xlsx' ,col_names = TRUE,format_headers = TRUE)
      }
      
      
      
    } 
    else {
        
      tmp_path <- paste0(curr_upload_dir, '/', us.name) # create us dir
      dir.create(file.path(tmp_path))
      setwd(tmp_path)
      tmp_dir <- paste0(tmp_path,'/',period )           # Then creates period dir inside us dir
      dir.create(file.path(tmp_dir))
      setwd(tmp_dir)

      #save files here
      for (indicator in vec.indicators) {
        
        #tmp_df <- get( paste(org.unit.name,'_DF_',gsub(" ", "", indicator, fixed = TRUE) , sep=''), envir = user.env )
        tmp_df <- env_get(env = user.env , paste(org.unit.name,'_DF_',gsub(" ", "", indicator, fixed = TRUE) , sep=''))
        writexl::write_xlsx(x = tmp_df,path = paste0('DF_',gsub(" ", "", indicator, fixed = TRUE) ,".xlsx" ))
        
      }
      writexl::write_xlsx(x =df.warnings,path ='empty_cells_warning.xlsx' ,col_names = TRUE,format_headers = TRUE)
      }

    
  } 
  else {
    
    # create a new sub directory inside
    # the main path
    dir.create(file.path(upload_directory, upload.date))
    tmp_dir <- paste0(upload_directory, upload.date)
    setwd(tmp_dir)
    tmp_path_us <- paste0(tmp_dir, '/', us.name) # create us dir
    dir.create(file.path(tmp_path_us))
    setwd(tmp_path_us)
    tmp_dir_period <- paste0(tmp_path_us,'/',period )           # Then creates period dir inside us dir
    dir.create(file.path(tmp_dir_period))
    setwd(tmp_dir_period)
    # Save files here
    for (indicator in vec.indicators) {
      
      #tmp_df <- get( paste(org.unit.name,'_DF_',gsub(" ", "", indicator, fixed = TRUE) , sep=''), )
      tmp_df <- env_get(env = user.env , paste(org.unit.name,'_DF_',gsub(" ", "", indicator, fixed = TRUE) , sep=''))
      writexl::write_xlsx(x = tmp_df,path = paste0('DF_',gsub(" ", "", indicator, fixed = TRUE) ,".xlsx" ))
      
    }
    writexl::write_xlsx(x =df.warnings,path ='empty_cells_warning.xlsx' ,col_names = TRUE,format_headers = TRUE)
  }
  
  
}


getSheetNamesFormUSName <- function(vec.us.names, vec.sheet.names){
  
  vec_sheetnames <- c()
  tmp_vec_sheetnames <- vec.sheet.names
  for (item in vec.us.names) {
    
    if(item == "Hokwe"){
      sheet <- tmp_vec_sheetnames[which(grepl(pattern = "_Hokwe",x = tmp_vec_sheetnames,ignore.case = TRUE))]
    }else if(item == "Cumba"){
      
      sheet <- tmp_vec_sheetnames[which(grepl(pattern = "_Cumba",x = tmp_vec_sheetnames,ignore.case = TRUE))]
    }
    else {
      sheet <- tmp_vec_sheetnames[which(grepl(pattern = item,x = tmp_vec_sheetnames,ignore.case = TRUE))]
      
    }
    
    vec_sheetnames <- c(vec_sheetnames, sheet)
  }
  vec_sheetnames
  
}
  
  
getUsNameFromSheetNames <-function(vector, province){
  
  list_us_names <- list()
  vec_warnings <- c()
  counter <- 0 
  temp_vec <- c()
  for (item in vector) {
    
    counter <- counter + 1  
    if(!is.na(item)){
      
      dash_count = stringr::str_count(item,"_")
      
      if(dash_count==0) { # take the first item an check if it exists in vector_us from the paramConfig.R
        
        us_name <- item
        
        # Sample list of us_names
        if(province=="Maputo"){
          # Sample list of us_names
          my_list <- tolower(names(maputo_us_names_ids_dhis))
          
        } else if( province=="Gaza"){
          my_list <- tolower(names(gaza_us_names_ids_dhis))
        }
        
        
        # String to check
        substring_to_check <- us_name
        
        # Use lapply with %in% to check if the substring occurs in each element of the list
        substring_present <- unlist(lapply(my_list, function(x) substring_to_check %in% x))
        
        # Check if the substring is present in any element of the list
        if (any(substring_present)) {
          vec <- c(vec, us_name)
          list_us_names$health_facilities <- vec
        } else {
          vec_warnings <- c(vec_warnings,paste0(item, " nao consta no nome das US parametrizadas. posicao do sheet:  ",counter))
          list_us_names$warnings <- vec_warnings
        }
        
        
      }
      if(dash_count==1){
        
        if(!is.na(strsplit(item, "_")[[1]][1])){ # Ingore NA empty sheet names
          if(strsplit(item, "_")[[1]][1] != "Provincia"){
            
            us_name <- strsplit(item, "_")[[1]][1]
            
            
            if(province=="Maputo"){
              # Sample list of us_names
              my_list <- tolower(names(maputo_us_names_ids_dhis))
              
            } else if( province=="Gaza"){
              my_list <- tolower(names(gaza_us_names_ids_dhis))
            }

            
            
            # String to check
            substring_to_check <- tolower(us_name)
            
            # Use lapply with %in% to check if the substring occurs in each element of the list
            substring_present <- unlist(lapply(my_list, function(x) substring_to_check %in% x))
            
            # Check if the substring is present in any element of the list
            if (any(substring_present)) {
              temp_vec <- c(temp_vec, us_name)
              list_us_names$health_facilities <- temp_vec
              
            } else {
              vec_warnings <- c(vec_warnings,paste0(item, " nao consta no nome das US parametrizadas. posicao do sheet:  ",counter))
              #shinyalert("Aviso",paste0(item, " nao consta no nome das US parametrizadas. posicao do sheet:  ",counter), type = "warning")
              list_us_names$warnings <- vec_warnings
              
            }
            
          }
        }
        else {
          vec_warnings <- c(vec_warnings,paste0(item, " nao consta no nome das US parametrizadas. posicao do sheet:  ",counter))
          #shinyalert("Aviso",paste0(item, " nao consta no nome das US parametrizadas. posicao do sheet:  ",counter), type = "warning")
          list_us_names$warnings <- vec_warnings
        }
        
      }
      else if(dash_count==2){
        
        if(!is.na(strsplit(item, "_")[[1]][2])){ # Ingore NA empty sheet names
          if(strsplit(item, "_")[[1]][2] != "Provincia"){
            
            us_name <-  paste0( strsplit(item, "_")[[1]][1], "_", strsplit(item, "_")[[1]][2])
            
            # Sample list of us_names
            if(province=="Maputo"){
              # Sample list of us_names
              my_list <- tolower(names(maputo_us_names_ids_dhis))
              
            } else if( province=="Gaza"){
              my_list <- tolower(names(gaza_us_names_ids_dhis))
            }
            
            
            # String to check
            substring_to_check <- tolower(us_name)
            
            # Use lapply with %in% to check if the substring occurs in each element of the list
            substring_present <- unlist(lapply(my_list, function(x) substring_to_check %in% x))
            
            # Check if the substring is present in any element of the list
            if (any(substring_present)) {
              temp_vec <- c(temp_vec, us_name)
              list_us_names$health_facilities <- temp_vec
            } else {
              vec_warnings <- c(vec_warnings,paste0(item, " nao consta no nome das US parametrizadas. posicao do sheet:  ",counter))
              #shinyalert("Aviso",paste0(item, " nao consta no nome das US parametrizadas. posicao do sheet:  ",counter), type = "warning")
              list_us_names$warnings <- vec_warnings
            }
            
          }
        }
        else {
          vec_warnings <- c(vec_warnings,paste0(item, " nao consta no nome das US parametrizadas. posicao do sheet:  ",counter))
          #shinyalert("Aviso",paste0(item, " nao consta no nome das US parametrizadas. posicao do sheet:  ",counter), type = "warning")
          list_us_names$warnings <- vec_warnings
        }
      }   
      else if(dash_count==3){
        
        if(!is.na(strsplit(item, "_")[[1]][3])){ # Ingore NA empty sheet names
          if(strsplit(item, "_")[[1]][3] != "Provincia"){
            
            us_name <- strsplit(item, "_")[[1]][3]
            
            # Sample list of us_names
            
            if(province=="Maputo"){
              # Sample list of us_names
              my_list <- tolower(names(maputo_us_names_ids_dhis))
              
            } else if( province=="Gaza"){
              my_list <- tolower(names(gaza_us_names_ids_dhis))
            }
            
            
            # String to check
            substring_to_check <- tolower(us_name)
            
            # Use lapply with %in% to check if the substring occurs in each element of the list
            substring_present <- unlist(lapply(my_list, function(x) substring_to_check %in% x))
            
            # Check if the substring is present in any element of the list
            if (any(substring_present)) {
              temp_vec <- c(temp_vec, us_name)
              list_us_names$health_facilities <- temp_vec
              
            } else {
              vec_warnings <- c(vec_warnings,paste0(item, " nao consta no nome das US parametrizadas. posicao do sheet:  ",counter))
              #shinyalert("Aviso",paste0(item, " nao consta no nome das US parametrizadas. posicao do sheet:  ",counter), type = "warning")
              list_us_names$warnings <- vec_warnings
              
            }
            
          }
        } else {
          vec_warnings <- c(vec_warnings,paste0(item, " nao consta no nome das US parametrizadas. posicao do sheet:  ",counter))
          #shinyalert("Aviso",paste0(item, " nao consta no nome das US parametrizadas. posicao do sheet:  ",counter), type = "warning")
          list_us_names$warnings <- vec_warnings
        }
      } 
      else if(dash_count==4){
        
        if(!is.na(strsplit(item, "_")[[1]][4])){ # Ingore NA empty sheet names
          if(strsplit(item, "_")[[1]][4] != "Provincia"){
            
            us_name <-  paste0( strsplit(item, "_")[[1]][3], "_", strsplit(item, "_")[[1]][4])
            
            # Sample list of us_names
           
            if(province=="Maputo"){
              # Sample list of us_names
              my_list <- tolower(names(maputo_us_names_ids_dhis))
              
            } else if( province=="Gaza"){
              my_list <- tolower(names(gaza_us_names_ids_dhis))
            }
            
            # String to check
            substring_to_check <- tolower(us_name)
            
            # Use lapply with %in% to check if the substring occurs in each element of the list
            substring_present <- unlist(lapply(my_list, function(x) substring_to_check %in% x))
            
            # Check if the substring is present in any element of the list
            if (any(substring_present)) {
              temp_vec <- c(temp_vec, us_name)
              list_us_names$health_facilities <- temp_vec
              
            } else {
              vec_warnings <- c(vec_warnings,paste0(item, " nao consta no nome das US parametrizadas. posicao do sheet:  ",counter))
              #shinyalert("Aviso",paste0(item, " nao consta no nome das US parametrizadas. posicao do sheet:  ",counter), type = "warning")
              list_us_names$warnings <- vec_warnings
              
            }
            
          }
        }
        else {
          vec_warnings <- c(vec_warnings,paste0(item, " nao consta no nome das US parametrizadas. posicao do sheet:  ",counter))
          #shinyalert("Aviso",paste0(item, " nao consta no nome das US parametrizadas. posicao do sheet:  ",counter), type = "warning")
          list_us_names$warnings <- vec_warnings
        }
      } 
      else{
        vec_warnings <- c(vec_warnings,paste0(item, " nao consta no nome das US parametrizadas. posicao do sheet:  ",counter))
       # shinyalert("Aviso",paste0(item, " nao consta no nome das US parametrizadas. posicao do sheet:  ",counter), type = "warning")
        list_us_names$warnings <- vec_warnings
      }
    }
  }
  list_us_names
}

getDataSetDataElements  <- function(base.url, dataset.id) {
  
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

getDatimDataValueSet    <- function(url.api.dhis.datasets,dataset.id, period, org.unit){
  
  # Create the API URL
  url_datavalues  <-  paste0(url.api.dhis.datasets,'api/33/dataValueSets','.json?', 'dataSet=',dataset.id,'&period=',period,'&orgUnit=',org.unit)
  http_content    <-  content(GET(url_datavalues, authenticate(dhis2.username, dhis2.password),timeout(45) ),as = "text",type = 'application/json'  )
  df_datavalueset =   fromJSON(http_content) %>% as.data.frame
    
   if(nrow(df_datavalueset) > 1 ){
     
    df_datavalueset = df_datavalueset[,c(5,3,4,8,9,10)]
    names(df_datavalueset)[1]  <- "Dataelement"
    names(df_datavalueset)[2]  <- "Period"
    names(df_datavalueset)[3]  <- "OrgUnit"
    names(df_datavalueset)[4]  <- "CategoryOptionCombo"
    names(df_datavalueset)[5]  <- "AttributeOptionCombo"
    names(df_datavalueset)[6]  <- "Value"
    df_datavalueset
    
  } else {
    return(NULL)
  }

  
}

getUsName <- function(org.unit){
  
  us_name <- which(us_names_ids_dhis==org.unit)
  names(us_name)
}


#' getDhisDataElement ->  Busca o ID do DataElement do datim com base no id do DataElement do DHIS CCS
#' @param cat.opt.comb categoryoptioncombouid
#' @param data.element dataelementuid   
#' @examples
#' getDhisDataElement("YiMCSzx23b",""YiMCSzx23b")
getDhisDataElement<- function(cat.opt.comb, data.element) {
  
  dhis_data_elementid <- NA
  
  index <- which(datim_mapping_template$dhiscategoryoptioncombouid==cat.opt.comb & datim_mapping_template$dhisdataelementuid== data.element )
  
  dhis_data_elementid <- datim_mapping_template[index,]$dataelementuid[1]
  
  dhis_data_elementid
  
}

#' getDhisCategoryOptionCombo ->  Busca o ID do CategoryOptionCombo do datim com base no id do CategoryOptionCombo do DHIS CCS
#' @param cat.opt.comb categoryoptioncombouid
#' @param data.element dataelementuid   
#' @examples
#' CategoryOptionCombo("YiMCSzx23b",""YiMCSzx23b")
getDhisCategoryOptionCombo <- function(cat.opt.comb, data.element) {
  
  cat_option_comb <- NA
  
  
  index <- which(datim_mapping_template$dhiscategoryoptioncombouid==cat.opt.comb & datim_mapping_template$dhisdataelementuid== data.element )
  
  cat_option_comb <- datim_mapping_template[index,]$categoryoptioncombouid[1]
  
  
  cat_option_comb
  
}

#' get99UnusedDataElements ->  Busca o valor do comentario (observation) na planilha de mapeamento para usar como variavel de decisao de report
#' @param cat.opt.comb categoryoptioncombouid
#' @param data.element dataelementuid   
#' @examples
#' get99UnusedDataElements("YiMCSzx23b",""YiMCSzx23b")
get99UnusedDataElements<- function(cat.opt.comb, data.element) {
  
  ignore_row <- NA
  
  index <- which(datim_mapping_template$dhiscategoryoptioncombouid==cat.opt.comb & datim_mapping_template$dhisdataelementuid== data.element )
  
  ignore_row <- datim_mapping_template[index,]$observation[1]
  
  ignore_row
  
}

#' getDhisOrgUnit ->  Busca o ID da orgUnit do datim com base no id do orgUnit do DHIS CCS
#' @param  ccs.orgunit orgUnit ID
#' @examples
#' getDhisOrgUnit("YiMCSzx23b")
getDhisOrgUnit <-  function(ccs.orgunit) {
  
  df_ccs_data_exchange_orgunits <- get("df_ccs_data_exchange_orgunits", envir = .GlobalEnv)
  
  index <- which(df_ccs_data_exchange_orgunits$ccs_orgunit_id==ccs.orgunit )
  
  df_ccs_data_exchange_orgunits[index,]$orgunit_internal_id[1]
  
}

aDjustDhisPeriods <- function(period) {
  
  if(substr(period,5,6)=='Q1'){
    return(paste0(as.integer(substr(period,1,4)) +1,'Q1'))
    return(paste0(substr(period,1,4),'Q2'))
  } else if(substr(period,5,6)=='Q2'){
    return(paste0(substr(period,1,4),'Q3'))
  } else if(substr(period,5,6)=='Q3'){
    return(paste0(substr(period,1,4),'Q4'))
  } else if(substr(period,5,6)=='Q4'){     # Q4 no DHIS corresponde ao ano seguinte no periodo do reporte do PEPFAR
    return(paste0(as.integer(substr(period,1,4)) +1,'Q1'))
  }
  
}

isMissing <- function(x) { x== "" | is.na(x) } 


indicatorsToString <- function(vec)  {
  
  t <- ""     
  for (v in vec) {
   if(t==""){
     t <- paste0(t, v)
   }else {
     t <- paste0(t, ", ", v) 
   }

}
  t
  
  }

#' getProgramStages ->  Busca os estagios de um programa
#' @param  base.url base.url 
#' @param  program.id program.id
#' @examples
#' getProgramStages("YiMCSzx23b")
getProgramStages <- function(base.url, program.id) {
  ## location pode ser distrito , provincia
  url <-
    paste0(
      base.url,
      paste0(
        "api/programs/",
        program.id,
        "/programStages?fields=id,name"
      )
    )
  r <- content(GET(url, authenticate(dhis2.username, dhis2.password)), as = "parsed")
  do.call(rbind.data.frame, r$programStages)
}

getDataElements <- function(base.url) {
  url <-
    paste0(base.url,
           "api/dataElements?fields=id,name,shortName&paging=false")
  r <- content(GET(url, authenticate(dhis2.username, dhis2.password)), as = "parsed")
  do.call(rbind.data.frame, r$dataElements)
}

getEnrollments <- function(base.url,org.unit, program.id ) {
  
  url <-    paste0( base.url,paste0("api/tracker/enrollments?orgUnit=", org.unit, "&program=",program.id, "&ouMode=DESCENDANTS", "&skipPaging=TRUE"  )  )
  
  
  r <- content(GET(url, authenticate(dhis2.username, dhis2.password), timeout(35)), as = "parsed")
  
  # criar um df vazio para armazenar os Enrrolments
  df_te <- data.frame(matrix(ncol = 8, nrow =  length(r$instances) ))
  x <- c("enrollment", "trackedEntity", "status" , "createdAt", "deleted", "orgUnit" , "orgUnitName", "enrolledAt")
  colnames(df_te) <- x
  
  
  if(typeof(r)=="list" && length(r$instances)>0) {
    
    
    
    # Iterar a lista para extrair os attributes
    for (i in 1:length(r$instances)) {
      
      
      enrollment <- r$instances[[i]]
      enrollment_id <- enrollment$enrollment
      tracked_entity_id <- enrollment$trackedEntity
      status <- enrollment$status
      createdAt <- enrollment$createdAt
      enrolledAt <- enrollment$enrolledAt
      deleted <- enrollment$deleted
      org_unit <- enrollment$orgUnit
      orgUnitName <- enrollment$orgUnitName
      
      
      # prencher o df df_te
      df_te$enrollment[i] <-  enrollment_id 
      df_te$trackedEntity[i] <- tracked_entity_id
      df_te$status[i] <- status
      df_te$createdAt[i] <-  createdAt
      df_te$deleted[i] <- deleted
      df_te$orgUnit[i] <- org_unit
      df_te$orgUnitName[i] <- orgUnitName
      df_te$enrolledAt[i] <- enrolledAt
      
    }
    
  }
  
  
  df_te
  
}

getTrackedInstances <- function(base.url, program.id,org.unit) {
  ## location pode ser distrito , provincia
  url <-
    paste0(
      base.url,
      paste0(
        "api/tracker/trackedEntities?orgUnit=",
        org.unit,
        "&program=",
        program.id,
        "&ouMode=DESCENDANTS",
        "&skipPaging=TRUE"
      )
    )
  r <- content(GET(url, authenticate(dhis2.username, dhis2.password),timeout(35)), as = "parsed")
  
  # criar um df vazio para armazenar os TE
  df_te <- data.frame(matrix(ncol = 8, nrow =  length(r$instances) ))
  x <- c("sector_testagem", "ano_livro", "nr_livro" , "mod_testagem", "pagina", "linha_regist" ,"org_unit", "trackedEntity")
  colnames(df_te) <- x
  
  
  if(typeof(r)=="list" && length(r$instances)>0) {
    
    
    
    # Iterar a lista para extrair os attributes
    for (i in 1:length(r$instances)) {
      
      
      tracked_entity <- r$instances[[i]]
      tracked_entity_id <- tracked_entity$trackedEntity
      org_unit <- tracked_entity$orgUnit
      tracked_entity_sector <- ""
      tracked_entity_ano_livro <- ""
      tracked_entity_nr_livro <- ""
      tracked_entity_mod_test <- ""
      tracked_entity_pagina <- ""
      tracked_entity_linha_reg <- ""
      
      list_atributos <- tracked_entity$attributes
      
      for (v in 1:length(list_atributos)) {
        
        atributo <- list_atributos[[v]]
        displayName <- atributo$displayName
        value <- atributo$value
        
        if(displayName=="Setor de Testagem"){
          tracked_entity_sector <- value
          
        } else  if(displayName=="Ano do livro"){
          tracked_entity_ano_livro <- value
          
        } else if(displayName=="Número do livro"){
          tracked_entity_nr_livro <- value
          
        } else if(displayName=="Modalidade De Testagem"){
          tracked_entity_mod_test<- value
          
        } else if (displayName=="Página"){
          tracked_entity_pagina<- value
          
        } else if (displayName=="Linha do Registo"){
          tracked_entity_linha_reg <- value
          
        }
      }
      
      # prencher o df df_te    x <- c("sector_testagem", "ano_livro", "nr_livro" , "mod_testagem", "pagina", "linha_regist" ,"org_unit")
      df_te$sector_testagem[i] <-  tracked_entity_sector 
      df_te$ano_livro[i] <- tracked_entity_ano_livro
      df_te$nr_livro[i] <- tracked_entity_nr_livro
      df_te$mod_testagem[i] <-  tracked_entity_mod_test
      df_te$trackedEntity[i] <- tracked_entity_id
      df_te$orgUnit[i] <- org_unit
      df_te$pagina[i] <- tracked_entity_pagina
      df_te$linha_regist[i] <- tracked_entity_linha_reg
      
      
    }
    
  }
  
  
  df_te
  
}

getOrganizationUnits <- function(base.url, location_id) {
  ## location pode ser distrito , provincia
  url <-
    paste0(
      base.url,
      paste0(
        "api/organisationUnits/",
        location_id,
        "?includeDescendants=true&level=3&fields=id,name,shortName&paging=false"
      )
    )
  r <- content(GET(url, authenticate(dhis2.username, dhis2.password)), as = "parsed")
  do.call(rbind.data.frame, r$organisationUnits)
}

getTrackerEvents <- function(base.url,org.unit,program.id, program.stage.id){
  url <-
    paste0(base.url,
           paste0(
             "api/tracker/events.json?orgUnit=",
             org.unit,
             '&program=',
             program.id,
             '&programStage=',
             program.stage.id,
             "&ouMode=DESCENDANTS&skipPaging=true"
           )
    )
  
  # Get the data
  r2 <- content(GET(url, authenticate(dhis2.username, dhis2.password),timeout(35)),as = "parsed")
  
  if(typeof(r2)=="list" && length(r2$instances)>0) {
    
    vec_size_datavalues <- c()
    for(event in r2$instances){
      
      size <- length( event$dataValues)
      vec_size_datavalues <-  c(vec_size_datavalues,size)
    }
    
    # primeiro evento da lista com maior  nr de colunas
    index = which.max(vec_size_datavalues)
    #event_metadata_col_names <- names(r2$instances[[index]])
    #event_values_col_names   <- names(r2$instances[[index]]$dataValues[[1]])
    # Quantidade de variaveis de cada evento
    #length(r2$instances[[index]]$dataValues)
    #df_events_col_names <- c(event_metadata_names, event_values_col_names)
    
    # inicializar o df 
    df_event_values <- do.call(rbind.data.frame,r2$instances[[1]]$dataValues)
    df_event_values <- df_event_values[1,]
    df_event_values$storedBy <- ""
    df_event_values$programStage <- ""
    df_event_values$status <- ""
    df_event_values$created <- ""
    #df_event_values$notes <- ""
    df_event_values$dueDate <- ""
    df_event_values$orgUnit <- ""
    df_event_values$orgUnitName <- ""
    df_event_values$program <- ""
    df_event_values$trackedEntityIntance <- ""
    df_event_values$eventDate <- ""
    df_event_values$deleted <- ""
    df_event_values$href <- ""
    df_event_values$enrollment <- ""
    df_event_values$attributeCategoryOptions <- ""
    df_event_values$attributeOptionCombo <- ""
    df_event_values$event <- ""
    df_event_values$enrollmentStatus <- ""
    df_event_values <- df_event_values[0,]
    
    #  Junta todos  dataValues  de todos  eventos
    
    for (index in 1:length(r2$instances)) {
      
      if(length(r2$instances[[index]]$dataValues)>0) {
        
        temp <-  do.call(rbind.data.frame,r2$instances[[index]]$dataValues)
        
        
        temp$storedBy <-r2$instances[[index]]$storedBy
        temp$programStage <-r2$instances[[index]]$programStage
        temp$status <- r2$instances[[index]]$status
        temp$created <- r2$instances[[index]]$created
        
        # Existem eventos sem notas
        #if(length(r2$instances[[index]]$notes)>0){
        #
        #  temp$notes <- r2$instances[[index]]$notes
        #}
        
        temp$dueDate <- r2$instances[[index]]$dueDate
        temp$orgUnit <- r2$instances[[index]]$orgUnit
        temp$orrgUnitName <- r2$instances[[index]]$orgUnitName
        temp$program <- r2$instances[[index]]$program
        temp$trackedEntityIntance <- r2$instances[[index]]$trackedEntityInstance
        temp$eventDate <- r2$instances[[index]]$eventDate
        temp$deleted <- r2$instances[[index]]$deleted
        temp$href <- r2$instances[[index]]$href
        temp$enrollment <- r2$instances[[index]]$enrollment
        temp$attributeCategoryOptions <- r2$instances[[index]]$attributeCategoryOptions
        temp$attributeOptionCombo <- r2$instances[[index]]$attributeOptionCombo
        temp$event <- r2$instances[[index]]$event
        temp$enrollmentStatus <- r2$instances[[index]]$enrollmentStatus
        
        
        df_event_values <- rbind.fill(df_event_values, temp)
      }
    }
    
  }
  
  df_event_values
  
  
}

findDataElementByID <- function(id){
  
  dataElement <- dataElements[which(dataElements$id==id),]
  as.character(dataElement$name)
}


findTrackedInstanceByID <- function(id){
  
  trackedInstance <- trackedInstance[which(trackedInstances$Instance==id),]
  as.character(trackedInstance$name)
}


findProgramStageByID <- function(id){
  
  stage <- programStages[which(programStages$id==id),]
  as.character(stage$name)
}


getStageNameByID <- function(stage.id, df.stages){
  
  stage_name <- df.stages$name[which(df.stages$id==stage.id)]
  stage_name
}


