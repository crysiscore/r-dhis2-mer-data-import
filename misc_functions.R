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
  
  
  tmp <- get(datavalueset.template.name, envir = .GlobalEnv)
  df <- filter(tmp, dataElement==data.element.id & categoryoptioncombo==category.option.combo.id )
  
  total_rows <- nrow(df)
  if(total_rows==0){
    df_error_tmp_empty$dhisdataelementuid[1] <- data.element.id
    df_error_tmp_empty$dhiscategoryoptioncombouid[1] <- category.option.combo.id
    df_error_tmp_empty$indicator[1] <- indicator.name
    df_error_tmp_empty$error[1] <- 'NOT FOUND'
    df_error_tmp<- rbind.fill(df_error_tmp, df_error_tmp_empty)
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
    assign(x = "error_log_dhis_import",value =df_error_tmp, envir = .GlobalEnv )
    return('Duplicado')
  }
  
}


#' getDEValueOnExcell ->  Le o valor de uma cell no ficheiro excell
#' @param cell.ref referencia da cell
#' @param  excell.mapping.template location do ficheiro
#' @param sheet.name nome do sheet
#' @examples 
#' val  <- function(cell.ref, excell.mapping.template, sheet.name)


getDEValueOnExcell <- function(cell.ref, excell.mapping.template, sheet.name){
  
  data_value <- tryCatch({
    
    tmp <-   read_xlsx(path = excell.mapping.template,sheet = sheet.name,range = paste0(cell.ref,':',cell.ref),col_names = FALSE)
    if(nrow(tmp)==0){
      warning_msg <- paste0( "Empty excell cell ", cell.ref, ' on file ', excell.mapping.template , ' sheetname ' ,sheet.name)
      tmp  <- get('error_log_dhis_import_empty',envir = .GlobalEnv)
      df_error_tmp <- get('error_log_dhis_import',envir = .GlobalEnv)
      
      tmp$sheetname[1] <- sheet.name
      tmp$excellfilename[1] <- excell.mapping.template
      tmp$excell_cell_ref[1] <- cell.ref
      tmp$observation[1] <- warning_msg
      tmp$error[1] <- "Warning"
      message("Warning :", warning_msg)
      df_error_tmp  <- rbind.fill(df_error_tmp, tmp)
      assign(x = "error_log_dhis_import",value =df_error_tmp, envir = .GlobalEnv )
      empty_value <- ""
      return(empty_value)
      
    } else if (nrow(tmp)==1) {
      tmp[[1]]
    }
    
  },
  error = function(cond) {
    error_msg <- paste0( "Error reading from excell: ", cell.ref, 'on file:', excell.mapping.template , ' sheetname:' ,sheet.name)
    tmp  <- get('error_log_dhis_import_empty',envir = .GlobalEnv)
    df_error_tmp <- get('error_log_dhis_import',envir = .GlobalEnv)
    tmp$sheetname[1] <- sheet.name
    tmp$excellfilename[1] <- excell.mapping.template
    tmp$excell_cell_ref[1] <- cell.ref
    tmp$error[1] <- error_msg
    message(error_msg)
    df_error_tmp <- rbind.fill(df_error_tmp, tmp)
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


# MER CT
#excell.mapping.template <- 'MER CARE & TREATMENT.xlsx'
#file_to_import <- 'Linked_DHIS_MER_Templates_v1.0.xlsx'
#sheet_name <- 'MER_CT'


checkDataConsistency <- function(excell.mapping.template, file.to.import, sheet.name, vec.indicatior ){
  
  for (indicator in vec_mer_ct_indicators) {
    # GET excell values
    setwd(wd)
    # Carregar os indicadores do ficheiro do template de Mapeamento  & excluir os dataElements que nao reportamos (observation==99)
    tmp_df <- read_xlsx(path =paste0('mapping/',excell.mapping.template), sheet = indicator , skip = 1 )
    tmp_df <- filter(tmp_df, is.na(observation) )
    tmp_df$check <- ""
    tmp_df$value <- ""
    
    
    #Verificar se todos os dataElements do Ficheiro de Mapeamento existem no DHIS2: check=TRUE -> OK  (check=FALSE, check=Duplicado) -> Nao existem
    tmp_df$check  <- mapply(checkIFDataElementExistsOnTemplate,tmp_df$dhisdataelementuid,tmp_df$dhiscategoryoptioncombouid ,"datavalueset_template_dhis2_mer_ct",indicator)
    
    #Get excell values
    setwd('data/')
    tmp_df$value <-  mapply(getDEValueOnExcell,tmp_df$excell_cell_ref, file_to_import, sheet.name=sheet_name)
    
    assign(paste('DF_',gsub(" ", "", indicator, fixed = TRUE) , sep=''), tmp_df , envir = .GlobalEnv)
    
    
  }
}


