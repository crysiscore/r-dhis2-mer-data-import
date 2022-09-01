
# -- ---------------------------- Configuration parameters  ------------------------------ --

# 1 - change to project location on server
wd <- '/home/agnaldo/Git/ccs_datim_maping/'


# 2 - DHIS2 API ENDPOINTS : https://docs.dhis2.org/en/develop/using-the-api/dhis-core-version-237/data.html

api_dhis_base_url <- "https://mail.ccsaude.org.mz:5459/"
api_dhis_datasets <- 'https://mail.ccsaude.org.mz:5459/api/dataSets/'
api_dhis_datasetvalues_endpoint <- '/api/33/dataValueSets'


# 3 - DHIS2 DATASET NAMES (DO NOT CHANGE)
mer_datasets_names <- c("MER C&T"  = "ct", "MER ATS" = "ats" , "MER SMI" = "smi" , "MER PREVENTION"="prevention", "MER HEALTH SYSTEM"="hs")

# 4 - CCS DHIS2 Datasets IDs (DO NOT CHANGE)
mer_datasets_ids          <- c("MER C&T"  = "WmHFZdWbzU2", "MER ATS" = "b2a0MuC3lb1" , "MER SMI" = "OQDQqOI7brV" , "MER PREVENTION"="JbLlGyAwQkd", "MER HEALTH SYSTEM"="AAw69FykQil")
dataset_id_mer_ct         <- 'WmHFZdWbzU2'
dataset_id_mer_ats        <- 'b2a0MuC3lb1'
dataset_id_mer_prevention <- 'JbLlGyAwQkd'
dataset_id_mer_smi        <- 'OQDQqOI7brV'
dataset_id_mer_hs         <- 'AAw69FykQil'

# Periods
vec_reporting_periods_2020 <- c("")
vec_reporting_periods_2021 <- 
vec_reporting_periods_2022 <- c("202204")
  
# 5 - MER TEMPLATES -  Planilhas de mapeamento
excell_mapping_template_mer_prevention <- 'MER PREVENTION.xlsx'
excell_mapping_template_mer_ct         <- 'MER CARE & TREATMENT.xlsx'
excell_mapping_template_mer_ats        <- 'MER ATS.xlsx'
excell_mapping_template_mer_smi        <- 'MER SMI.xlsx'
excell_mapping_template_mer_hs         <- 'MER HEALTH SYSTEMS.xlsx' 

# 6 - DF Value templates (DO NOT CHANGE)
vec_mer_dataset_valuetemplates_names <- c("datavalueset_template_dhis2_mer_ct","datavalueset_template_dhis2_mer_ats" ,"datavalueset_template_dhis2_mer_prevention",
                                          "datavalueset_template_dhis2_mer_smi","datavalueset_template_dhis2_mer_hs")

# 7 - INDICATORS VS  DHIS2 DATASET MAPPING
# Cada indicador foi mapeado numa folha (sheet) na  planilha excell que representa cada dataset no DHIS. ( 5)
vec_mer_ct_indicators          <- c('DSD TX NEW', 'DSD TX CURR',  'DSD TX RTT', 'DSD TX ML','DSD PMCT ART','DSD TX PVLS','DSD TX TB','DSD TB ART')
vec_mer_ats_indicators         <- c('DSD HTS TST','DSD HTS INDEX','DSD HTS SELF','DSD TB STAT')
vec_mer_smi_indicators         <- c('DSD PMTCT STAT','DSD PMTCT EID','DSD PMTCT HEI POS','DSD CXCA SCRN','DSD CXCA TX')
vec_mer_prevention_indicators  <- c('DSD PREP','DSD TB PREV','DSD GEND GBV', 'DSD FPINT SITE')
vec_mer_hs_indicators           <- c('','','', '') #TODO

# 8 - Nomes das US que aparecem nos sheets gerados automaticamente nos temlates de importacao: J. Mandlate
us_names_sheet <- c("1Junho","Albazine","Hulene","MavalaneCS"  , "MavalaneHG" ,  "Pescadores" ,  "Romao", "1Maio", "PCanico", "AltMae","CCivil", 
                   "HCMPed","Malhangalene", "Maxaquene","PCimento22","Porto", "Bagamoio","HPI","Inhagoia","MagoanineA","MTendas", "Zimpeto",
                   "Inhaca","Catembe", "Incassane","ChamanculoCS" ,"ChamanculoHG" ,"JMCS",  "JMHG",  "Xipamanine")

# 9 - Task names - Nomes dos estagios a executar durante os checks
task_check_consistency_1  <- "Verficar a integridade do ficheiro de importacao"
task_check_consistency_2  <- "Verificar se todos os dataElements do Ficheiro de Mapeamento existem no DHIS2"
task_check_consistency_3  <- "Buscar valores para cada indicador: "
task_4  <- " "
task_5  <- " "
task_6  <- " "
task_7  <- " "

