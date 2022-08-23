library(jsonlite)
library(dplyr)

# Configuration parameters
wd <- '/home/agnaldo/Git/ccs_datim_maping/'
setwd(wd)
source(file = 'misc_functions.R')
source(file = 'credentials.R')
load(file = 'error_log.RData')


# API:DHIS2
api_dhis_base_url <- "https://mail.ccsaude.org.mz:5459/dhis/"
api_dhis_datasets <- 'https://mail.ccsaude.org.mz:5459/api/dataSets/'


# DHIS2 Datasets IDs
dataset_id_mer_ct <- 'WmHFZdWbzU2'
dataset_id_mer_ats <- 'b2a0MuC3lb1'
dataset_id_mer_prevention <- 'JbLlGyAwQkd'
dataset_id_mer_smi <- 'OQDQqOI7brV'
dataset_id_mer_hs <- 'AAw69FykQil'




# INDICATORS VS  DHIS DATASET MAPPING
vec_mer_ct_indicators <- c('DSD TX NEW','DSD TX CURR','DSD TX RTT','DSD TX ML','DSD PMCT ART','DSD TX PVLS','DSD TX TB','DSD TB ART')
vec_mer_ats_indicators <- c('DSD HTS TST','DSD HTS INDEX','DSD HTS SELF','DSD TB STAT', 'DSD HTS INDEX COMMUNITY', 'DSD HTS TST COMMUNITY',  'DSD HTS TST COMMUNITY OTHER')

# Login to DHIS2
dhisLogin(dhis2.username = dhis2.username,dhis2.password = dhis2.password,base.url = api_dhis_base_url )


# Gerar o template de importacao de dados para cada dataset: MER CT, MER SMI, MER ATS, MEER PREVENTION, MER HEALTH SYSTEMS do DHIS2
datavalueset_template_dhis2_mer_ct <- getDhis2DatavalueSetTemplate(url.api.dhis.datasets = api_dhis_datasets, dataset.id = dataset_id_mer_ct)
datavalueset_template_dhis2_mer_ats <- getDhis2DatavalueSetTemplate(url.api.dhis.datasets = api_dhis_datasets, dataset.id = dataset_id_mer_ats)
datavalueset_template_dhis2_mer_smi <- getDhis2DatavalueSetTemplate(url.api.dhis.datasets = api_dhis_datasets, dataset.id = dataset_id_mer_smi)
datavalueset_template_dhis2_mer_prevention <- getDhis2DatavalueSetTemplate(url.api.dhis.datasets = api_dhis_datasets, dataset.id = dataset_id_mer_prevention)
datavalueset_template_dhis2_mer_hs <- getDhis2DatavalueSetTemplate(url.api.dhis.datasets = api_dhis_datasets, dataset.id = dataset_id_mer_hs)


# MER CT
excell.mapping.template <- 'MER CARE & TREATMENT.xlsx'
file_to_import <- 'Linked_DHIS_MER_Templates_v1.0.xlsx'
sheet_name <- 'MER_CT'

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
  assign(paste('DF_',gsub(" ", "", indicator, fixed = TRUE) , sep=''), tmp_df)

}


