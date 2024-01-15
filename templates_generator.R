# Generate config files for Monthly Uploads
# How to handle changes if mer indicators or org_units change

#Change here
working_dir <- '/Users/asamuel/Projects/ccs-datim-data-import'

# 1 - DHIS2 CCS (e-analysis) 
# Se houver mudancas nos indicadores do DHIS2 CCS (e-analysis) deve-se fazer os devidos mapeamentos nos ficheiros correspondentes aos datasets
# ('MER ATS COMMUNITY.xlsx',  'MER CARE & TREATMENT.xlsx'  , 'MER PREVENTION.xlsx','MER ATS.xlsx' ,'MER HEALTH SYSTEM.xlsx'  ,   'MER SMI.xlsx' ,  'NON MER MAPPING MDS.xlsx')
# e gerar novo template

# - dataset_templates/datimDataSetElementsCC.RData
load(paste0(working_dir, '/dataset_templates/datimDataSetElementsCC.RData' ))

df_datim_indicators <- df_datim_indicators[0,]
df_datim_indicators$indicator <-""


setwd(dir = paste0(working_dir, '/mapping/'))
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

save(df_datim_indicators,file = paste0(working_dir, '/dataset_templates/datimDataSetElementsCC.RData'))



# 2 -  PEPFAR DATIM 
# Se houver mudancas no DATIM  deve-se baixar o novo data dictionary do datim que inclui as mudancas nos data elements, identificar o indicador que sofreu allteracao e efectuar as mudancas
# ('MER ATS COMMUNITY.xlsx',  'MER CARE & TREATMENT.xlsx'  , 'MER PREVENTION.xlsx','MER ATS.xlsx' ,'MER HEALTH SYSTEM.xlsx'  ,   'MER SMI.xlsx' ,  'NON MER MAPPING MDS.xlsx')
# e geral novo template 

# Gerar apartir dos ficheiros mapeados exclusivamente para o formualrio DATIM
# Generate config files for Datim Uploadds
# dataset_templates/datimMappingTemplate.RData
load( file = paste0(working_dir, "/dataset_templates/datimDataSetElementsCC.RData"))
datim_mapping_template <- df_datim_indicators[0,]
datim_mapping_template$indicator <-""

setwd(dir =paste0(working_dir, '/mapping/Datim/'))
vec_files <- c('MER ATS COMMUNITY.xlsx',  'MER CARE & TREATMENT.xlsx'  , 'MER PREVENTION.xlsx','MER ATS.xlsx' ,
               'MER HEALTH SYSTEM.xlsx'  ,   'MER SMI.xlsx'  )

for (file  in vec_files) {
  
  sheet_names <- readxl::excel_sheets(path =file)
  
  
  for (sheet  in sheet_names) {
    if(sheet=="Data sets, elements and combos " | sheet == "Data sets, elements and combos"){
      
    } else {
      df_tmp <- readxl::read_xlsx(path = file,sheet = sheet,skip = 1,col_names = TRUE)
      if(ncol(df_tmp)>11){
        df_tmp <- df_tmp [,c(1:11)]
      }
      df_tmp$indicator <-  gsub(" ","",sheet)
      assign(x = gsub(" ","",sheet) ,value = df_tmp,envir = .GlobalEnv  )
      
      datim_mapping_template <- plyr::rbind.fill(datim_mapping_template,df_tmp )
    }
  }
  
}
setwd(dir = paste0(working_dir, '/dataset_templates'))
save(datim_mapping_template,file = 'datimMappingTemplate.RData')


# 3 - NOVO DATASET DHIS CCS (e-analysis) 
# Sempre que se cria um novo formulario no DHIS e se deseja importar dados atraves do API deve-se:

# 3.1  Para cada dataset/form  novo buscar o template e agregar no dataframe dataset_templates.RDATA
# Configurar os parametros do dataset a seguir
api_dhis_base_url <- "http://192.168.1.10:5400"
api_dhis_datasets <- 'https://mail.ccsaude.org.mz:5459/api/dataSets/'
dataset_id_mer_datim          <- "Z9agMHXo792"
dataset_id_non_mer            <- "LUsbbPX9hlO" # novo


# Uncomment the following lines
# load(file = paste0(working_dir, '/dataset_templates/dataset_templates.RDATA' ))
# NOT RUN ( Ja foi adicionado)
# datavalueset_template_dhis2_datim         <- getDhis2DatavalueSetTemplate(url.api.dhis.datasets = api_dhis_datasets, dataset.id = dataset_id_mer_datim)
# NOT RUN ( Ja foi adicionado)
# df_non_mer_mds <-   getDhis2DatavalueSetTemplate(url.api.dhis.datasets = api_dhis_datasets, dataset.id = dataset_id_non_mer) # Novo dataset


# Junta o novo data set com o template padrao
# datavalueset_template_dhis2_datim = plyr::rbind.fill(datavalueset_template_dhis2_datim,df_non_mer_mds)
# save(datavalueset_template_dhis2_datim, file =  paste0(working_dir, '/dataset_templates/dataset_templates.RDATA'))
     
#template_dhis2_datim <- datavalueset_template_dhis2_datim
#save(template_dhis2_datim, file = paste0(working_dir, '/dataset_templates/datim_dataelement_ids.RDATA'))

# 4 - NEW ORG UNITS
# If  orgunits are changed then re-generate the template
#df_ccs_data_exchange_orgunits <- readxl::read_xlsx(path = paste0(working_dir, '/mapping/CCS DATA EXCHANGE ORG UNITS.xlsx' ,col_names = TRUE))
#save(df_ccs_data_exchange_orgunits , file = paste0(working_dir, '/dataset_templates/ccsDataExchangeOrgUnits.RData'))
 