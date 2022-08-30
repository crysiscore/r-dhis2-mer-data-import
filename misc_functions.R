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
checkIFDataElementExistsOnTemplate  <- function(data.element.id, category.option.combo.id, datavalueset.template.name, indicator.name) {
  df_error_tmp_empty  <- get('error_log_dhis_import_empty',envir = .GlobalEnv)
  df_error_tmp <- get('error_log_dhis_import',envir = .GlobalEnv)
  wd<- get("wd", envir = .GlobalEnv)
  
  tmp <- get(datavalueset.template.name, envir = .GlobalEnv)
  df <- filter(tmp, dataElement==data.element.id & categoryoptioncombo==category.option.combo.id )
  
  total_rows <- nrow(df)
  if(total_rows==0){
    df_error_tmp_empty$dhisdataelementuid[1] <- data.element.id
    df_error_tmp_empty$dhiscategoryoptioncombouid[1] <- category.option.combo.id
    df_error_tmp_empty$indicator[1] <- indicator.name
    df_error_tmp_empty$error[1] <- 'NOT FOUND'
    df_error_tmp<- rbind.fill(df_error_tmp, df_error_tmp_empty)
    writexl::write_xlsx(x = df_error_tmp,path = paste0(wd ,'logs/log_execution_warning.xlsx'),col_names = TRUE,format_headers = TRUE)
    assign(x = "error_log_dhis_import",value =df_error_tmp, envir = .GlobalEnv )

    return(FALSE)
  } else if(total_rows==1){
    return(TRUE)
  } else if(total_rows>1){
    df_error_tmp_empty$dhisdataelementuid[1] <- data.element.id
    df_error_tmp_empty$dhiscategoryoptioncombouid[1] <- category.option.combo.id
    df_error_tmp_empty$indicator[1] <- indicator.name
    df_error_tmp_empty$error[1] <- 'DUPLICATED'
    df_error_tmp<- rbind.fill(df_error_tmp, df_error_tmp_empty)
    writexl::write_xlsx(x = df_error_tmp,path = paste0(wd ,'logs/log_execution_warning.xlsx'),col_names = TRUE,format_headers = TRUE)
    assign(x = "error_log_dhis_import",value =df_error_tmp, envir = .GlobalEnv )
    return('Duplicado')
  }
  
}


#' getDEValueOnExcell ->  Le o valor de uma cell no ficheiro excell
#' @param cell.ref referencia da cell
#' @param  file.to.import location do ficheiro
#' @param sheet.name nome do sheet
#' @examples 
#' val  <- function(cell.ref, file.to.import, sheet.name)
getDEValueOnExcell <- function(cell.ref, file.to.import, sheet.name){
  
  data_value <- tryCatch({
    wd <- get("wd", envir = .GlobalEnv)
    tmp <-   read_xlsx(path = file.to.import,sheet = sheet.name,range = paste0(cell.ref,':',cell.ref),col_names = FALSE)
    if(nrow(tmp)==0){
      warning_msg <- paste0( "Empty excell cell ", cell.ref, ' on  sheetname: ' ,sheet.name)
      tmp  <- get('error_log_dhis_import_empty',envir = .GlobalEnv)
      df_error_tmp <- get('error_log_dhis_import',envir = .GlobalEnv)
      
      tmp$sheetname[1] <- sheet.name
      tmp$excellfilename[1] <- path_file(file.to.import)
      tmp$excell_cell_ref[1] <- cell.ref
      tmp$observation[1] <- warning_msg
      tmp$error[1] <- "Warning"
      message("Warning :", warning_msg)
      df_error_tmp  <- rbind.fill(df_error_tmp, tmp)
      writexl::write_xlsx(x = df_error_tmp,path = paste0(wd ,'logs/log_execution_warning.xlsx'),col_names = TRUE,format_headers = TRUE)
      assign(x = "error_log_dhis_import",value =df_error_tmp, envir = .GlobalEnv )
      empty_value <- ""
      return(empty_value)
      
    } else if (nrow(tmp)==1) {
      tmp[[1]]
    }
    
  },
  error = function(cond) {
    error_msg <- paste0( "Error reading from excell: ", cell.ref, 'on sheetname:' ,sheet.name)
    tmp  <- get('error_log_dhis_import_empty',envir = .GlobalEnv)
    df_error_tmp <- get('error_log_dhis_import',envir = .GlobalEnv)
    tmp$sheetname[1] <- sheet.name
    tmp$excellfilename[1] <- path_file(file.to.import)
    tmp$excell_cell_ref[1] <- cell.ref
    tmp$error[1] <- error_msg
    message(error_msg)
    df_error_tmp <- rbind.fill(df_error_tmp, tmp)
    writexl::write_xlsx(x = df_error_tmp,path = paste0(wd, 'logs/log_execution_warning.xlsx'),col_names = TRUE,format_headers = TRUE)
    assign(x = "error_log_dhis_import",value =df_error_tmp, envir = .GlobalEnv )
    return(NA)
    
  },
  warning = function(cond) {
    # Choose a return value in case of warning
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
#' @param dataset.name nome do formualario dhis 2. ("MER C&T"  = "ct", "MER ATS" = "ats" , "MER SMI" = "smi" , "MER PREVENTION"="prevention", "MER HEALTH SYSTEM"="hs")
#' @examples 
#' is_consistent  <- checkDataConsistency(excell.mapping.template,file.to.import, dataset.name, sheet.name,vec.indicators)
checkDataConsistency <- function(excell.mapping.template, file.to.import,dataset.name, sheet.name, vec.indicators ){
 
  withProgress(message = 'Running checks',
               detail = 'This may take a while...', value = 0, {
                 
   wd <- get("wd",envir = .GlobalEnv)
  # carregar variaves e dfs para armazenar logs
  tmp_log_exec <- get('log_execution',envir = .GlobalEnv)
  vec_tmp_dataset_names <-  get('mer_datasets_names',envir = .GlobalEnv)
  tmp_log_exec_empty <- tmp_log_exec[1,]
  
  #Indicar a tarefa em execucao: task_check_consistency_1
  tmp_log_exec_empty$Datetime[1] <- substr(x = Sys.time(),start = 1, stop = 22)
  tmp_log_exec_empty$US[1] <- sheet.name
  tmp_log_exec_empty$Dataset[1] <- dataset.name
  tmp_log_exec_empty$task[1] <- get('task_check_consistency_1',envir = .GlobalEnv)
  message( "Stage 1: ", get('task_check_consistency_1',envir = .GlobalEnv))
  
  assign(x = "log_execution",value =tmp_log_exec, envir = .GlobalEnv )
  incProgress(1/(length(vec.indicators)+ 1), detail = paste("STAGE 1 - ", get('task_check_consistency_1',envir = .GlobalEnv) ))
  # Stage 1: Verficar o a integridade do ficheiro a ser importado
   total_error <- checkImportTamplateIntegrity(file.to.import = file.to.import,dataset.name =dataset.name ,sheet.name =sheet.name )
   if(total_error > 0) {
     
     for (i  in 1: length(vec.indicators) ) {
       incProgress(1/(length(vec.indicators)+ 1), detail = paste("STAGE II - ", get('task_check_consistency_2',envir = .GlobalEnv) ))
       
     }
     
     message('Integrity error')
    return('Integrity error')
   } else {
  # Stage 2: Verificar se todos os dataElements do Ficheiro de Mapeamento existem no DHIS2     
    
     #A tarefa anterior terminou com sucesso
     tmp_log_exec_empty$status[1] <- 'ok'
     tmp_log_exec <- plyr::rbind.fill(tmp_log_exec,tmp_log_exec_empty )
     assign(x = "log_execution",value =tmp_log_exec, envir = .GlobalEnv )
     writexl::write_xlsx(x = tmp_log_exec,path = paste0(wd, 'logs/log_execution.xlsx'),col_names = TRUE,format_headers = TRUE)
    
     
     #Indicar a tarefa em execucao: task_check_consistency_2
     tmp_log_exec_empty$Datetime[1] <- substr(x = Sys.time(),start = 1, stop = 22)
     tmp_log_exec_empty$US[1] <- sheet.name
     tmp_log_exec_empty$Dataset[1] <- dataset.name
     tmp_log_exec_empty$task[1] <- get('task_check_consistency_2',envir = .GlobalEnv)
     tmp_log_exec_empty$status[1] <- 'processando...'
     message( "Stage 2: ", get('task_check_consistency_2',envir = .GlobalEnv))

     tmp_log_exec <- plyr::rbind.fill(tmp_log_exec,tmp_log_exec_empty )
     assign(x = "log_execution",value =tmp_log_exec, envir = .GlobalEnv )
     writexl::write_xlsx(x = tmp_log_exec,path = paste0(wd, 'logs/log_execution.xlsx'),col_names = TRUE,format_headers = TRUE)
     datavalueset_template <- getDataValuesetName(dataset.name)
     
     for (indicator in vec.indicators) {
       # GET excell values
       setwd(wd)
       # Carregar os indicadores do ficheiro do template de Mapeamento  & excluir os dataElements que nao reportamos (observation==99)
       tmp_df <- read_xlsx(path =paste0('mapping/',excell.mapping.template), sheet = indicator , skip = 1 )
       tmp_df <- filter(tmp_df, is.na(observation) )
       tmp_df$check <- ""
       tmp_df$value <- ""
       
       tmp_df$check  <- mapply(checkIFDataElementExistsOnTemplate,tmp_df$dhisdataelementuid,tmp_df$dhiscategoryoptioncombouid ,datavalueset_template,indicator)
       
       #Indicar a tarefa em execucao : task_check_consistency_3
       tmp_log_exec_empty$Datetime[1] <- substr(x = Sys.time(),start = 1, stop = 22)
       tmp_log_exec_empty$US[1] <- sheet.name
       tmp_log_exec_empty$Dataset[1] <- dataset.name
       tmp_log_exec_empty$task[1] <- paste0(get('task_check_consistency_3',envir = .GlobalEnv), indicator)
       message(  "Stage 3: ", get('task_check_consistency_3',envir = .GlobalEnv))
       writexl::write_xlsx(x = tmp_log_exec_empty,path = paste0(wd, 'logs/log_execution.xlsx'),col_names = TRUE,format_headers = TRUE)
       assign(x = "log_execution",value =tmp_log_exec, envir = .GlobalEnv )
       
       #Get excell values
       setwd('data/')
       tmp_df$value <-  mapply(getDEValueOnExcell,tmp_df$excell_cell_ref, file.to.import, sheet.name=sheet.name)
       
       assign(paste('DF_',gsub(" ", "", indicator, fixed = TRUE) , sep=''), tmp_df , envir = .GlobalEnv)
       #A tarefa anterior terminou com sucesso
       tmp_log_exec_empty$status[1] <- 'ok'
       tmp_log_exec <- plyr::rbind.fill(tmp_log_exec,tmp_log_exec_empty )
       writexl::write_xlsx(x = tmp_log_exec,path = paste0(wd, 'logs/log_execution.xlsx'),col_names = TRUE,format_headers = TRUE)
       incProgress(1/(length(vec.indicators)+ 1), detail = paste("STAGE III - Processando  o indicador: ", indicator , " " ))
       }
    

     assign(x = "log_execution",value =tmp_log_exec, envir = .GlobalEnv )
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
checkImportTamplateIntegrity  <- function(file.to.import,dataset.name,sheet.name){
  wd <- get("wd",envir = .GlobalEnv)
  setwd(wd)
  df_checks <- read_xlsx(path ='mapping/dhis_mer_checks.xlsx', sheet = 1 ,col_names = TRUE  )
  
  df_cells_to_ckeck  <- filter(df_checks, Dataset ==dataset.name)
  df_cells_to_ckeck$value_on_template <-""
  df_cells_to_ckeck$error_message <-""
  total_errors <-0
  
  for (index  in 1:nrow(df_cells_to_ckeck)) {
    
      cell_ref <- df_cells_to_ckeck$Cell[index]
      cell_value <- df_cells_to_ckeck$Value[index]
      
      value_on_template <- getDEValueOnExcell( cell_ref ,file.to.import = file.to.import,sheet.name = sheet.name )
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
    writexl::write_xlsx(x = df_cells_to_ckeck,path = 'errors/template_errors.xlsx')
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
