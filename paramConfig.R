
# -- ---------------------------- Configuration parameters  ------------------------------ --

# change to project location on server
wd <- '/home/agnaldo/Git/ccs_datim_maping/'


# API:DHIS2 URLs
api_dhis_base_url <- "https://mail.ccsaude.org.mz:5459/dhis/"
api_dhis_datasets <- 'https://mail.ccsaude.org.mz:5459/api/dataSets/'

# DDHIS2 DATASET NAMES
mer_datasets_names <- c("MER C&T"  = "ct", "MER ATS" = "ats" , "MER SMI" = "smi" , "MER PREVENTION"="prevention", "MER HEALTH SYSTEM"="hs")

# DHIS2 Datasets IDs
dataset_id_mer_ct         <- 'WmHFZdWbzU2'
dataset_id_mer_ats        <- 'b2a0MuC3lb1'
dataset_id_mer_prevention <- 'JbLlGyAwQkd'
dataset_id_mer_smi        <- 'OQDQqOI7brV'
dataset_id_mer_hs         <- 'AAw69FykQil'

# MER TEMPLATES -  Planilhas de mapeamento
excell.mapping.template.mer.prevention <- 'MER PREVENTION.xlsx'
excell.mapping.template.mer.ct         <- 'MER CARE & TREATMENT.xlsx'
excell.mapping.template.mer.ats        <- 'MER ATS.xlsx'
excell.mapping.template.mer.smi        <- 'MER SMI.xlsx'
excell.mapping.template.mer.hs         <- 'MER HEALTH SYSTEMS.xlsx' 


# INDICATORS VS  DHIS DATASET MAPPING
# Cada indicador foi mapeado numa folha (sheet) na  planilha excell que representa cada dataset no DHIS.
vec_mer_ct_indicators          <- c('DSD TX NEW', 'DSD TX CURR',  'DSD TX RTT', 'DSD TX ML','DSD PMCT ART','DSD TX PVLS','DSD TX TB','DSD TB ART')
vec_mer_ats_indicators         <- c('DSD HTS TST','DSD HTS INDEX','DSD HTS SELF','DSD TB STAT')
vec_mer_smi_indicators         <- c('DSD PMTCT STAT','DSD PMTCT EID','DSD PMTCT HEI POS','DSD CXCA SCRN','DSD CXCA TX')
vec_mer_prevention_indicators  <- c('DSD PREP','DSD TB PREV','DSD GEND GBV', 'DSD FPINT SITE')



source(file = 'misc_functions.R') # ficheiro com diversas funcoes
source(file = 'credentials.R')    # Variaveis de conexao do DHIS2
load(file = 'rdata.RData')        # ficheiro com DF que armazenam temporariamente os logs e algumas variaveis usadas no codigo

