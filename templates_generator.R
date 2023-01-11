# 
# 1- clone project
#   git clone https://github.com/crysiscore/r-dhis2-mer-data-import.git 
# 
# 2 - Create app  and history dir on server
#  mkdir -p  /data_ssd_1/shiny-apps/dhis/apps
#  mkdir -p  /data_ssd_1/shiny-apps/dhis/history
#  mkdir -p  /data_ssd_1/shiny-apps/dhis/history/mensal
#  mkdir -p  /data_ssd_1/shiny-apps/dhis/history/datim
#  cp r-dhis2-mer-data-import/dataset_templates/template_errors.xlsx  /data_ssd_1/shiny-apps/dhis/history/
#  cp r-dhis2-mer-data-import/dataset_templates/DHIS2 UPLOAD HISTORY.xlsx /data_ssd_1/shiny-apps/dhis/history/
#
# 3- create credential.R file inside root dir r-dhis2-mer-data-import and write dhis2.password =''  dhis2.password='' variable
#    touch r-dhis2-mer-data-import/credentials.R 
#
# 4- copy  r-dhis2-mer-data-import  to apps dir and give it any name
#    copy -r r-dhis2-mer-data-import /data_ssd_1/shiny-apps/dhis/apps/datim-app
#    
# 5- give read and write permission to all
#   sudo  chmod -R 777  /data_ssd_1/shiny-apps/dhis/apps
#   sudo  chmod -R 777  /data_ssd_1/shiny-apps/dhis/history
#
#    
# 6 - create a docker shiny-server 
# docker run -d --name shiny-server -p5460:3838 -v /data_ssd_1/shiny-apps/dhis/history:/uploads -v /data_ssd_1/shiny-apps/dhis/apps:/srv/shiny-server/ crysiscore/shiny-server:1.0
# 
# 8- acess the app through ther host url and port server-ip:5460/app-name


#RUn only if new  data elements/categoryoptionscombo/org units are created on DATIM



# In case of updating data elements in the mapping worksheets, the following files must be re-generated 
# 1 - dataset_templates/datimDataSetElementsCC.RData
load("~/Git/ccs_datim_maping/dataset_templates/datimDataSetElementsCC.RData")
df_datim_indicators <- df_datim_indicators[0,]
df_datim_indicators$indicator <-""


vec_files <- c('MER ATS COMMUNITY.xlsx',  'MER CARE & TREATMENT.xlsx'  , 'MER PREVENTION.xlsx','MER ATS.xlsx' ,
               'MER HEALTH SYSTEM.xlsx'  ,   'MER SMI.xlsx'  )

for (file  in vec_files) {

  sheet_names <- readxl::excel_sheets(path = paste0('mapping/',file))


  for (sheet  in sheet_names) {
    if(sheet=="Data sets, elements and combos " | sheet == "Data sets, elements and combos"){

    } else {
      df_tmp <- readxl::read_xlsx(path = paste0('mapping/',file),sheet = sheet,skip = 1,col_names = TRUE)
      df_tmp$indicator <-  gsub(" ","",sheet)
      assign(x = gsub(" ","",sheet) ,value = df_tmp,envir = .GlobalEnv  )

      df_datim_indicators <- plyr::rbind.fill(df_datim_indicators,df_tmp )
    }
  }

}

save(df_datim_indicators,file = 'dataset_templates/datimDataSetElementsCC.RData')

# 
# 2 -dataset_templates/dataset_templates.RDATA
#   
api_dhis_base_url <- "http://192.168.1.10:5400"
api_dhis_datasets <- 'https://mail.ccsaude.org.mz:5459/api/dataSets/'
dataset_id_mer_datim          <- "RU5WjDrv2Hx"
datavalueset_template_dhis2_datim         <- getDhis2DatavalueSetTemplate(url.api.dhis.datasets = api_dhis_datasets, dataset.id = dataset_id_mer_datim)
save(datavalueset_template_dhis2_datim, file = 'dataset_templates/dataset_templates.RDATA')

# 
# 4- If  orgunits are changed then re-generate the template
df_ccs_data_exchange_orgunits <- readxl::read_xlsx(path = 'mapping/CCS DATA EXCHANGE ORG UNITS.xlsx' ,col_names = TRUE)
save(df_ccs_data_exchange_orgunits , file = 'dataset_templates/ccsDataExchangeOrgUnits.RData')
# 
# 
