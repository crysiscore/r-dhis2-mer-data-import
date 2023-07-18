# Generate config files for Monthly Uploads
# 1 - dataset_templates/datimDataSetElementsCC.RData
load("~/Git/ccs_datim_maping/dataset_templates/datimDataSetElementsCC.RData")
df_datim_indicators <- df_datim_indicators[0,]
df_datim_indicators$indicator <-""


setwd(dir = '~/Git/ccs_datim_maping/mapping/')
vec_files <- c('MER ATS COMMUNITY.xlsx',  'MER CARE & TREATMENT.xlsx'  , 'MER PREVENTION.xlsx','MER ATS.xlsx' ,
               'MER HEALTH SYSTEM.xlsx'  ,   'MER SMI.xlsx' ,  'NON MER MAPPING MDS.xlsx')

for (file  in vec_files) {

  sheet_names <- readxl::excel_sheets(path = file)


  for (sheet  in sheet_names) {
    if(sheet=="Data sets, elements and combos " | sheet == "Data sets, elements and combos"){

    } else {
      df_tmp <- readxl::read_xlsx(path = ,file,sheet = sheet,skip = 1,col_names = TRUE)
      df_tmp$indicator <-  gsub(" ","",sheet)
      assign(x = gsub(" ","",sheet) ,value = df_tmp,envir = .GlobalEnv  )

      df_datim_indicators <- plyr::rbind.fill(df_datim_indicators,df_tmp )
    }
  }

}

save(df_datim_indicators,file = '../dataset_templates/datimDataSetElementsCC.RData')

# Gerar apartir dos ficheiros mapeados exclusivamente para o formualrio DATIM
# Generate config files for Datim Uploadds
# 1 - dataset_templates/datimMappingTemplate.RData
load("~/Git/ccs_datim_maping/dataset_templates/datimDataSetElementsCC.RData")
datim_mapping_template <- df_datim_indicators[0,]
datim_mapping_template$indicator <-""

setwd(dir = '~/Git/ccs_datim_maping/mapping/Datim/')

vec_files <- c('MER ATS COMMUNITY.xlsx',  'MER CARE & TREATMENT.xlsx'  , 'MER PREVENTION.xlsx','MER ATS.xlsx' ,
               'MER HEALTH SYSTEM.xlsx'  ,   'MER SMI.xlsx'  )

for (file  in vec_files) {
  
  sheet_names <- readxl::excel_sheets(path =file)
  
  
  for (sheet  in sheet_names) {
    if(sheet=="Data sets, elements and combos " | sheet == "Data sets, elements and combos"){
      
    } else {
      df_tmp <- readxl::read_xlsx(path = file,sheet = sheet,skip = 1,col_names = TRUE)
      df_tmp$indicator <-  gsub(" ","",sheet)
      assign(x = gsub(" ","",sheet) ,value = df_tmp,envir = .GlobalEnv  )
      
      datim_mapping_template <- plyr::rbind.fill(datim_mapping_template,df_tmp )
    }
  }
  
}

save(datim_mapping_template,file = 'dataset_templates/datimMappingTemplate.RData')


# 2 - Templates : Dataset_templates/dataset_templates.RDATA
# Para cada dataset novo deve-se buscar o template e agregar no dataframe dataset_templates.RDATA
#

api_dhis_base_url <- "http://192.168.1.10:5400"
api_dhis_datasets <- 'https://mail.ccsaude.org.mz:5459/api/dataSets/'
dataset_id_mer_datim          <- "Z9agMHXo792"
dataset_id_non_mer            <- "LUsbbPX9hlO"

load(file ='/home/agnaldo/Git/ccs_datim_maping/dataset_templates/dataset_templates.RDATA' )
#datavalueset_template_dhis2_datim         <- getDhis2DatavalueSetTemplate(url.api.dhis.datasets = api_dhis_datasets, dataset.id = dataset_id_mer_datim)
# Novo dataset
df_non_mer_mds <-   getDhis2DatavalueSetTemplate(url.api.dhis.datasets = api_dhis_datasets, dataset.id = dataset_id_non_mer)
# Junta o novo data set com o template padrao
datavalueset_template_dhis2_datim = plyr::rbind.fill(datavalueset_template_dhis2_datim,df_non_mer_mds)
save(datavalueset_template_dhis2_datim, file = '/home/agnaldo/Git/ccs_datim_maping/dataset_templates/dataset_templates.RDATA')
     
     
template_dhis2_datim <- datavalueset_template_dhis2_datim
save(template_dhis2_datim, file = 'dataset_templates/datim_dataelement_ids.RDATA')

# 
# 3- If  orgunits are changed then re-generate the template
df_ccs_data_exchange_orgunits <- readxl::read_xlsx(path = 'mapping/CCS DATA EXCHANGE ORG UNITS.xlsx' ,col_names = TRUE)
save(df_ccs_data_exchange_orgunits , file = 'dataset_templates/ccsDataExchangeOrgUnits.RData')
# 
# 
