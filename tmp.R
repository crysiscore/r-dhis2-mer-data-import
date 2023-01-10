
# In case of updating indicators in the mapping worksheets, the following files must be re-generated 
# 1 - dataset_templates/datimDataSetElementsCC.RData
# load("~/Git/ccs_datim_maping/dataset_templates/datimDataSetElementsCC.RData")
# df_datim_indicators <- df_datim_indicators[0,]
# 
# df_datim_indicators$indicator <-""
# 
# vec_files <- c('MER ATS COMMUNITY.xlsx',  'MER CARE & TREATMENT.xlsx'  , 'MER PREVENTION.xlsx','MER ATS.xlsx' ,
#                'MER HEALTH SYSTEM.xlsx'  ,   'MER SMI.xlsx'  )
# 
# for (file  in vec_files) {
# 
#   sheet_names <- readxl::excel_sheets(path = paste0('mapping/',file))
# 
# 
#   for (sheet  in sheet_names) {
#     if(sheet=="Data sets, elements and combos " | sheet == "Data sets, elements and combos"){
# 
#     } else {
#       df_tmp <- readxl::read_xlsx(path = paste0('mapping/',file),sheet = sheet,skip = 1,col_names = TRUE)
#       df_tmp$indicator <-  gsub(" ","",sheet)
#       assign(x = gsub(" ","",sheet) ,value = df_tmp,envir = .GlobalEnv  )
# 
#       df_datim_indicators <- plyr::rbind.fill(df_datim_indicators,df_tmp )
#     }
#   }
# 
# }
# 
# save(df_datim_indicators,file = 'dataset_templates/datimDataSetElementsCC.RData')
# 
# 
# 2 -dataset_templates/dataset_templates.RDATA
#   
# api_dhis_base_url <- "http://192.168.1.10:5400"
# api_dhis_datasets <- 'https://mail.ccsaude.org.mz:5459/api/dataSets/'
# dataset_id_mer_datim          <- "RU5WjDrv2Hx"
# datavalueset_template_dhis2_datim         <- getDhis2DatavalueSetTemplate(url.api.dhis.datasets = api_dhis_datasets, dataset.id = dataset_id_mer_datim)
# save(datavalueset_template_dhis2_datim, file = 'dataset_templates/dataset_templates.RDATA')
# 
# 4- If  orgunits are changed then re-generate the template
# df_ccs_data_exchange_orgunits <- readxl::read_xlsx(path = 'mapping/CCS DATA EXCHANGE ORG UNITS.xlsx' ,col_names = TRUE)
# save(df_ccs_data_exchange_orgunits , file = 'dataset_templates/ccsDataExchangeOrgUnits.RData')
# 
# 
