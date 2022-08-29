library(jsonlite)
library(dplyr)


source(file = 'paramConfig.R') # Carrega os paramentros 
setwd(wd)

# Login to DHIS2
dhisLogin(dhis2.username = dhis2.username,dhis2.password = dhis2.password,base.url = api_dhis_base_url )


# Gerar o template de importacao de dados para cada dataset: MER CT, MER SMI, MER ATS, MEER PREVENTION, MER HEALTH SYSTEMS do DHIS2
datavalueset_template_dhis2_mer_ct <- getDhis2DatavalueSetTemplate(url.api.dhis.datasets = api_dhis_datasets, dataset.id = dataset_id_mer_ct)
datavalueset_template_dhis2_mer_ats <- getDhis2DatavalueSetTemplate(url.api.dhis.datasets = api_dhis_datasets, dataset.id = dataset_id_mer_ats)
datavalueset_template_dhis2_mer_smi <- getDhis2DatavalueSetTemplate(url.api.dhis.datasets = api_dhis_datasets, dataset.id = dataset_id_mer_smi)
datavalueset_template_dhis2_mer_prevention <- getDhis2DatavalueSetTemplate(url.api.dhis.datasets = api_dhis_datasets, dataset.id = dataset_id_mer_prevention)
datavalueset_template_dhis2_mer_hs <- getDhis2DatavalueSetTemplate(url.api.dhis.datasets = api_dhis_datasets, dataset.id = dataset_id_mer_hs)



file_to_import <- 'Linked_DHIS_MER_Templates_v1.0.xlsx'
sheet_name_ct <- 'MER_Prevention'
sheet_name_ats <- 'MER_Prevention'
sheet_name_smi <- 'MER_Prevention'
sheet_name_prevention <- 'MER_Prevention'



#Get excell values
setwd('data/')
# check sheet name exists 
vec_sheets <- excel_sheets(path = file_to_import)

if(sheet_name %in% vec_sheets){
  
  for (indicator in vec_mer_prevention_indicators) {
    # GET excell values
    setwd(wd)
    # Carregar os indicadores do ficheiro do template de Mapeamento  & excluir os dataElements que nao reportamos (observation==99)
    tmp_df <- read_xlsx(path =paste0('mapping/',excell.mapping.template.mer.prevention), sheet = indicator , skip = 1 )
    tmp_df <- filter(tmp_df, is.na(observation) )
    tmp_df$check <- ""
    tmp_df$value <- ""
    
    
    #Verificar se todos os dataElements do Ficheiro de Mapeamento existem no DHIS2: check=TRUE -> OK  (check=FALSE, check=Duplicado) -> Nao existem
    tmp_df$check  <- mapply(checkIFDataElementExistsOnTemplate,tmp_df$dhisdataelementuid,tmp_df$dhiscategoryoptioncombouid ,"datavalueset_template_dhis2_mer_prevention",indicator)
    
    #Get excell values
    setwd('data/')
    tmp_df$value <-  mapply(getDEValueOnExcell,tmp_df$excell_cell_ref, file_to_import, sheet.name=sheet_name)
    
    assign(paste('DF_',gsub(" ", "", indicator, fixed = TRUE) , sep=''), tmp_df , envir = .GlobalEnv)
    
    
  }
  
  
  print(paste0( "DATASET: ", sheet_name,
                " | EMPTY CELLS: ",nrow(filter(error_log_dhis_import, sheetname==sheet_name & error=="Warning"))
                , " | ERRORS:  ", nrow(filter(error_log_dhis_import, sheetname==sheet_name & error!="Warning")) ))
  
  
  
  
  
} else{
   message("Sheet : ",sheet_name , " nao foi encontrando no ficheiro ", file_to_import)
}

# 
# tmp <- DF_DSDTXML[,c(10,9,13)]
# tmp$value <- as.numeric(tmp$value )
# tmp <- filter(tmp, !is.na(value))
# names(tmp)[1]<- "dataElement"
# names(tmp)[2]<- "categoryOptionCombo"
# toJSON(x = tmp, dataframe = 'rows', pretty = T)

