# Generate config files for Monthly Uploads
# How to handle changes if mer indicators or org_units change

#Change here
working_dir <- '/Users/asamuel/Projects/ccs-datim-data-import'
source(paste0(working_dir,'/misc_functions.R'))
##############################################################################################################
# 1 - DHIS2 CCS (e-analysis)                                                                                 #
# Se houver mudancas nos indicadores do DHIS2 CCS (e-analysis) deve-se fazer os devidos mapeamentos nos      #
# ficheiros correspondentes aos datasets                                                                     #
# ('MER ATS COMMUNITY.xlsx',  'MER CARE & TREATMENT.xlsx'  , 'MER PREVENTION.xlsx','MER ATS.xlsx' ,          #
# 'MER HEALTH SYSTEM.xlsx'  ,   'MER SMI.xlsx' ,  'NON MER MAPPING MDS.xlsx')                                #
# e gerar novo template                                                                                      #
##############################################################################################################
load(paste0(working_dir, '/dataset_templates/datimDataSetElementsCC.RData' ))
df_datim_indicators <- df_datim_indicators[0,]
df_datim_indicators$indicator <-""

setwd(dir = paste0(working_dir, '/mapping/DHIS2/'))
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

# filter 99 
df_datim_indicators <- subset(df_datim_indicators, is.na(observation)   )
save(df_datim_indicators,file = paste0(working_dir, '/dataset_templates/datimDataSetElementsCC.RData'))


##############################################################################################################
# 2 -  PEPFAR DATIM                                                                                          #  
# Se houver mudancas no DATIM  deve-se baixar o novo data dictionary do datim que inclui as mudancas nos data#
#elements, identificar o indicador que sofreu allteracao e efectuar as mudancas                              #
# ('MER ATS COMMUNITY.xlsx',  'MER CARE & TREATMENT.xlsx'  , 'MER PREVENTION.xlsx','MER ATS.xlsx' ,          #
#'MER HEALTH SYSTEM.xlsx'  ,   'MER SMI.xlsx' ,  'NON MER MAPPING MDS.xlsx')                                 #
# e geral novo template                                                                                      #
# Gerar apartir dos ficheiros mapeados exclusivamente para o formualrio DATIM                                #
##############################################################################################################
#Change here
working_dir <- '/Users/asamuel/Projects/ccs-datim-data-import'
load( file = paste0(working_dir, "/dataset_templates/datimDataSetElementsCC.RData"))
datim_mapping_template <- df_datim_indicators[0,]
#datim_mapping_template$indicator <-""

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

# filter 99
# O filtro 99 - sera feito no final da comparacao dos dados do DHIS2 e dos templates do DATIM.

# datim_mapping_template <- subset(datim_mapping_template, is.na(observation)   )

setwd(dir = paste0(working_dir, '/dataset_templates'))
save(datim_mapping_template,file = 'datimMappingTemplate.RData')

##############################################################################################################
# 3- Gera template de dados do DATIM FORM no e-analisys                                                      #
# Se o formulario MER - DATIM FORM for alterado deve-se gerar um novo template                               #
#Uncomment the following lines                                                                               #
##############################################################################################################
api_dhis_datasets <- 'https://mail.ccsaude.org.mz:5459/api/dataSets/'
dataset_id_mer_datim          <- "Z9agMHXo792"
source('../conf/credentials.R')

# NOT RUN ( Ja foi adicionado)
datavalueset_template_dhis2_datim         <- getDhis2DatavalueSetTemplate(url.api.dhis.datasets = api_dhis_datasets, dataset.id = dataset_id_mer_datim)
# NOT RUN ( Ja foi adicionado)
save(datavalueset_template_dhis2_datim, file =  paste0(working_dir, '/dataset_templates/dataset_templates.RDATA'))

##############################################################################################################
 # template_dhis_ccs_forms
 # 4- Gera template de dados dos Formularios Mensais (CT,SMI,PREVENTION,Health systems, NON MEER) do e-analisys 
 #dataset_id_mer_ct             <- 'WmHFZdWbzU2'
 #ataset_id_mer_ats            <- 'b2a0MuC3lb1'
 #dataset_id_mer_prevention     <- 'JbLlGyAwQkd'
 #dataset_id_mer_smi            <- 'OQDQqOI7brV'
 #dataset_id_mer_hs             <- 'AAw69FykQil'
 #dataset_id_mer_ats_community  <- 'aWAxctvA9jY'
 #dataset_id_non_mer            <- "LUsbbPX9hlO" # novo
 ##############################################################################################################
 api_dhis_datasets <- 'https://mail.ccsaude.org.mz:5459/api/dataSets/'
 ccs_monthly_forms_ids         <- c('WmHFZdWbzU2','b2a0MuC3lb1','JbLlGyAwQkd', 'OQDQqOI7brV','AAw69FykQil', 'aWAxctvA9jY','LUsbbPX9hlO')
datavalueset_template_dhis2_ccs_forms <- data.frame()

for (dataset_uid in ccs_monthly_forms_ids) {
  
  df_tmporario   <- getDhis2DatavalueSetTemplate(url.api.dhis.datasets = api_dhis_datasets, dataset.id = dataset_uid)
  if(nrow(df_tmporario)>0){
    datavalueset_template_dhis2_ccs_forms <- plyr::rbind.fill(datavalueset_template_dhis2_ccs_forms,df_tmporario)
  } else {
    message("Erro ao baixar o datavalueset: ", dataset_uid)
  }

}
save(datavalueset_template_dhis2_ccs_forms, file =  paste0(working_dir, '/dataset_templates/datavalueset_template_dhis2_ccs_forms.RDATA'))
 
 
##############################################################################################################
# NOT RUN -> este codigo vai correr no server     
#template_dhis2_datim <- datavalueset_template_dhis2_datim
#save(template_dhis2_datim, file = paste0(working_dir, '/dataset_templates/datim_dataelement_ids.RDATA'))

# 4 - NEW ORG UNITS
# If  orgunits are changed then re-generate the template
#df_ccs_data_exchange_orgunits <- readxl::read_xlsx(path = paste0(working_dir, '/mapping/CCS DATA EXCHANGE ORG UNITS.xlsx'), col_names = TRUE)  DEPRICATED
df_ccs_data_exchange_orgunits <- readxl::read_xlsx(path = paste0(working_dir,'/conf/paramConfig.xlsx'), sheet = 'ccs_datim_exchange_orgunits', col_names = TRUE)
save(df_ccs_data_exchange_orgunits , file = paste0(working_dir, '/dataset_templates/ccsDataExchangeOrgUnits.RData'))
#writexl::write_xlsx(x = df_ccs_data_exchange_orgunits, path = paste0(working_dir, '/mapping/CCS DATA EXCHANGE ORG UNITS.xlsx'))
 ##############################################################################################################################################

##
base.url <- 'https://mail.ccsaude.org.mz:5459/'
gaza_location_id <- "rtVqizS7g8s"
df_gaza_orgunits <- getOrganizationUnits(base.url = base.url, location_id =gaza_location_id)
working_dir <-getwd()
xls_fle <- readxl::read_xlsx(path = paste0(working_dir, '/data/Datim/datim/Gaza/02 - CT DHIS Import v1.3 M2.7_Gaza.xlsx') ,col_names = TRUE)# get sheet names 

