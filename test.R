str_json <- toJSON(x = df_all_indicators , dataframe = 'rows', pretty = T)
# API:DHIS2 URLs

api_dhis_base_url <- "http://192.168.1.10:5400"
api_dhis_datasets <- 'https://mail.ccsaude.org.mz:5459/api/dataSets/'

period <- "202204"
org.unit <- "FTLV9nOnAFC"
complete.date <- "2022-04-21"
dataset.id <- dataset_id_mer_ats

merIndicatorsToJson <- function(dataset.id, complete.date, period , org.unit, vec.indicators){
  
  dataSetID    <- dataset.id
  completeDate <- complete.date
  period       <- period
  orgUnit      <- org.unit
  df_all_indicators <- NULL
  vec.indicators <- vec_mer_ats_indicators
  
  json_header <- paste0( "\"dataSet\":\"",dataSetID, "\" ," ,
                         "\"completeDate\":\"",completeDate , "\" ," ,
                         "\"period\":\"", period , "\" ," ,
                         "\"orgUnit\":\"",orgUnit,"\" , " ,  
                         "\"dataValues\":" ) 
  
  # junta os df de todos indicadores processados
  for (indicator in vec.indicators) {
      df                <- get(paste('DF_',gsub(" ", "", indicator, fixed = TRUE) , sep=''), envir = .GlobalEnv)
      if(nrow(df) > 0){
        
        df_all_indicators <- plyr::rbind.fill(df_all_indicators, df)
      }
     
    
  }
  
  df_all_indicators <- df_all_indicators[, c(10,9,13)]
  df_all_indicators <- subset(df_all_indicators, !(is.na(value) | value =="")) # remover dataelements sem dados
  names(df_all_indicators)[1] <-  "dataElement"
  names(df_all_indicators)[2] <- "categoryOptionCombo"
  names(df_all_indicators)[3] <- "value"
  
  # converte os valores para json
  json_data_values <- as.character(toJSON(x = df_all_indicators , dataframe = 'rows'))
  
  #Unir com o header para formar o payload
  json <- paste0( "{ ", json_header, json_data_values, "  }")
  

  
}



apiDhisSendDataValues <- function(json){

  # url da API

  base.url <- paste0(get('api_dhis_base_url',envir = .GlobalEnv),get("api_dhis_datasetvalues_endpoint",envir = .GlobalEnv))
  
  
  # send patient to openmrs
  status <- POST(url = base.url,
                 body = json, config=authenticate(get("dhis2.username",envir = .GlobalEnv), get("dhis2.password",envir = .GlobalEnv)),
                 add_headers("Content-Type"="application/json") )
  
  # The reponse from server will be an object with the following structure
  # Response [http://192.168.1.10:5400/api/33/dataValueSets]
  # Date: 2022-09-01 10:17
  # Status: 200
  # Content-Type: application/json;charset=UTF-8
  # Size: 861 B
   return(status)
  
}
