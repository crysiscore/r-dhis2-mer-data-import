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



getDataElements <- function(base.url) {
  url <-
    paste0(base.url,
           "api/dataElements?fields=id,name,shortName&paging=false")
  r <- content(GET(url, authenticate(dhis2.username, dhis2.password)), as = "parsed")
  do.call(rbind.data.frame, r$dataElements)
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
        "&ouMode=DESCENDANTS"
      )
    )
  r <- content(GET(url, authenticate(dhis2.username, dhis2.password),timeout(10)), as = "parsed")
  
  # criar um df vazio para armazenar os TE
  df_te <- data.frame(matrix(ncol = 7, nrow =  length(r$instances) ))
  x <- c("Nome", "Apelido", "idade" , "Telefone", "Nid", "trackedEntity", "orgUnit")
  colnames(df_te) <- x
  
  
  if(typeof(r)=="list" && length(r$instances)>0) {
    
    
    
    # Iterar a lista para extrair os attributes
    for (i in 1:length(r$instances)) {
      
      
      tracked_entity <- r$instances[[i]]
      tracked_entity_id <- tracked_entity$trackedEntity
      org_unit <- tracked_entity$orgUnit
      tracked_entity_name <- ""
      tracked_entity_telefone <- ""
      tracked_entity_surname <- ""
      tracked_entity_nid <- ""
      tracked_entity_age <- ""
      
      list_atributos <- tracked_entity$attributes
      
      for (v in 1:length(list_atributos)) {
        
        atributo <- list_atributos[[v]]
        displayName <- atributo$displayName
        value <- atributo$value
        
        if(displayName=="Nome"){
          tracked_entity_name <- value
          
        } else  if(displayName=="Apelido"){
          tracked_entity_surname <- value
          
        } else if(displayName=="NID"){
          tracked_entity_nid <- value
          
        } else if(displayName=="Telefone"){
          tracked_entity_telefone<- value
          
        } else if (displayName=="Idade"){
          tracked_entity_age<- value
          
        }
      }
      
      # prencher o df df_te
      df_te$Nome[i] <-  tracked_entity_name 
      df_te$Apelido[i] <- tracked_entity_surname
      df_te$Telefone[i] <- tracked_entity_telefone
      df_te$Nid[i] <-  tracked_entity_nid
      df_te$trackedEntity[i] <- tracked_entity_id
      df_te$orgUnit[i] <- org_unit
      df_te$idade[i] <- tracked_entity_age
      
      
    }
    
  }
  
  
  df_te
  
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
  r2 <- content(GET(url, authenticate(dhis2.username, dhis2.password),timeout(5)),as = "parsed")
  
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

calc_age <- function(birthDate, refDate = Sys.Date()) {
  
  require(lubridate)
  
  period <- as.period(interval(birthDate, refDate),
                      unit = "year")
  
  period$year
  
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



