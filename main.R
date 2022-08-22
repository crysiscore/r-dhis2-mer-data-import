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


# DHIS2 Datasets
dataset_id_mer_ct <- 'WmHFZdWbzU2'

# INDICATORS VS  DHIS DATASET MAPPING
vec_mer_ct_indicators <- c('DSD TX NEW','DSD TX CURR','DSD TX RTT','DSD TX ML','DSD PMCT ART','DSD TX PVLS','DSD TX TB','DSD TB ART')

# Login to DHIS2
dhisLogin(dhis2.username = dhis2.username,dhis2.password = dhis2.password,base.url = api_dhis_base_url )


# Gerar o template de importacao de dados do DHIS2
datavalueset_template_dhis2_mer_ct <- getDhis2DatavalueSetTemplate(url.api.dhis.datasets = api_dhis_datasets, dataset.id = dataset_id_mer_ct)

# Carregar o indicador do ficheiro de Mapeamento (POR INDICADOR) & excluir os dataElements que nao reportamos (observation==99)
df_dhis2_data_mapping <- read_xlsx(path = '~/Dropbox/Datim/MER CARE & TREATMENT.xlsx',sheet = 'DSD TX NEW',skip = 1 )
df_dhis2_data_mapping <- filter(df_dhis2_data_mapping, is.na(observation) )
df_dhis2_data_mapping$check <- ""
df_dhis2_data_mapping$value <- ""

#Verificar se todos os dataElements do Ficheiro de Mapeamento existem no DHIS2: check=TRUE -> OK  (check=FALSE, check=Duplicado) -> Nao existem
df_dhis2_data_mapping$check <- mapply(checkIFDataElementExistsOnTemplate,df_dhis2_data_mapping$dhisdataelementuid,df_dhis2_data_mapping$dhiscategoryoptioncombouid ,"datavalueset_template_dhis2_mer_ct")


# TODO - Verificar para todos indicadores  se existem algum DE nao mapeado

# Get excell values
setwd('data/')
excell.mapping.template <- 'Linked_DHIS_MER_Templates_v1.0.xlsx'
sheet.name <- 'MER_CT'
getDEValueOnExcell(cell.ref, excell.mapping.template, sheet.name)
df_dhis2_data_mapping$value <-  mapply(getDEValueOnExcell,df_dhis2_data_mapping$excell_cell_ref, excell.mapping.template, sheet.name)

tmp <- df_dhis2_data_mapping[,c(10,9,13)]
tmp$value <- as.numeric(tmp$value )
tmp <- filter(tmp, !is.na(value))
names(tmp)[1]<- "dataElement"
names(tmp)[2]<- "categoryOptionCombo"
toJSON(x = tmp, dataframe = 'rows', pretty = T)



