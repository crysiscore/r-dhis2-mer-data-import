
# -- ---------------------------- Configuration parameters  ------------------------------ --

# 1 - change to project location on server
wd <- '/home/agnaldo/Git/ccs_datim_maping/'

 
# 2 - DHIS2 API ENDPOINTS : https://docs.dhis2.org/en/develop/using-the-api/dhis-core-version-237/data.html 

api_dhis_base_url <- "http://127.0.0.1:5400/" 
api_dhis_datasets <- 'http://127.0.0.1:5400/api/dataSets/'
api_dhis_datasetvalues_endpoint <- 'api/33/dataValueSets'


# 3- DHIS2 DATASET NAMES (DO NOT CHANGE)
mer_datasets_names <- c("MER C&T"  = "ct", "MER ATS" = "ats" , "MER SMI" = "smi" , "MER PREVENTION"="prevention", "MER HEALTH SYSTEM"="hs")

# 4- CCS DHIS2 Datasets IDs (DO NOT CHANGE)
mer_datasets_ids          <- c("MER C&T"  = "WmHFZdWbzU2", "MER ATS" = "b2a0MuC3lb1" , "MER SMI" = "OQDQqOI7brV" , "MER PREVENTION"="JbLlGyAwQkd", "MER HEALTH SYSTEM"="AAw69FykQil")
dataset_id_mer_ct         <- 'WmHFZdWbzU2'
dataset_id_mer_ats        <- 'b2a0MuC3lb1'
dataset_id_mer_prevention <- 'JbLlGyAwQkd'
dataset_id_mer_smi        <- 'OQDQqOI7brV'
dataset_id_mer_hs         <- 'AAw69FykQil'

# 5- Reporting Periods   
vec_reporting_periods <- list("January 2020"= "202001", "February 2020" ="202002", "March 2020"  = "202003", "April 2020" = "202004", 
                                   "May 2020" = "202005",  "June 2020" = "202006", "July 2020" =  "202007",  "August 2020"  = "202008",
                                   "September 2020" = "202009",  "October 2020"  = "202010", "November 2020" = "202011" ,"December 2020"  = "202012",
                                   "January 2021"= "202101", "February 2021" ="202102",  "March 2021"  = "202103", "April 2021" =  "202104", 
                                   "May 2021" = "202105", "June 2021" = "202106", "July 2021" = "202107",  "August 2021"  = "202108",
                                   "September 2021" = "202109","October 2021"  = "202110","November 2021" = "202111" ,"December 2021"  = "202112",
                                   "January 2022"= "202201","February 2022" = "202202", "March 2022"  ="202203","April 202W" = "202204",
                                   "May 2022" = "202205","June 2022" =  "202206","July 2022" =  "202207", "August 2022"  =  "202208",
                                   "September 2022" = "202209", "October 2022" ="202210",  "November 2022"="202211" ,"December 2022" = "202212")

  
# 6- MER TEMPLATES -  Planilhas de mapeamento
excell_mapping_template_mer_prevention <- 'MER PREVENTION.xlsx'
excell_mapping_template_mer_ct         <- 'MER CARE & TREATMENT.xlsx'
excell_mapping_template_mer_ats        <- 'MER ATS.xlsx'
excell_mapping_template_mer_smi        <- 'MER SMI.xlsx'
excell_mapping_template_mer_hs         <- 'MER HEALTH SYSTEMS.xlsx' 

# 7- DF Value templates (DO NOT CHANGE)
vec_mer_dataset_valuetemplates_names <- c("datavalueset_template_dhis2_mer_ct","datavalueset_template_dhis2_mer_ats" ,"datavalueset_template_dhis2_mer_prevention",
                                          "datavalueset_template_dhis2_mer_smi","datavalueset_template_dhis2_mer_hs")

# 8- INDICATORS VS  DHIS2 DATASET MAPPING
# Cada indicador foi mapeado numa folha (sheet) na  planilha excell que representa cada dataset no DHIS. ( 5)
vec_mer_ct_indicators          <- c('DSD TX NEW', 'DSD TX CURR',  'DSD TX RTT', 'DSD TX ML','DSD PMCT ART','DSD TX PVLS','DSD TX TB','DSD TB ART')
vec_mer_ats_indicators         <- c('DSD HTS TST','DSD HTS INDEX','DSD HTS SELF','DSD TB STAT')
vec_mer_smi_indicators         <- c('DSD PMTCT STAT','DSD PMTCT EID','DSD PMTCT HEI POS','DSD CXCA SCRN','DSD CXCA TX')
vec_mer_prevention_indicators  <- c('DSD PREP','DSD TB PREV','DSD GEND GBV', 'DSD FPINT SITE')
vec_mer_hs_indicators           <- c('','','', '') #TODO

# 9- Nomes das US (org. units) que aparecem nos sheets gerados automaticamente nos temlates de importacao: J. Mandlate e os respectivos IDs no DHIS
us_names_ids_dhis <- list("1Junho"="FTLV9nOnAFC","Albazine" ="z8g2CUKUMCF","Hulene" = "Ma6u8rJ3faa","MavalaneCS" ="wafWzemVbX4" , "MavalaneHG"="aqka8xA6c7u" ,
                          "Pescadores" ="XNYN71gD1ps" ,  "Romao" = "cEqnyE9ahXG" , "1Maio"="iv9D81uQSZc", "PCanico"="ehepVdZYP6u", "AltMae"="kt468XD802Y","CCivil", 
                   "HCMPed"="aMaDE2B3W0b","Malhangalene" ="DFudgV3AdHI", "Maxaquene" ="Dz4coB1P1l5","PCimento22"="yGhwOKR4gBj","Porto"="DoyPc35A7zI", "Bagamoio"="aywqWn0Qkf8"
                   ,"HPI" = "QzORjiSM4Yz","Inhagoia"="EysXJHRv7xJ","MagoanineA"="o4HThkC2OEY","MTendas"="oKA7Ub02ze5", "Zimpeto"="KxezVOQ2TVR",
                   "Inhaca"="GJaIp0bKoXH","Catembe"="RYReGTxpYTF", "Incassane" ="MaU3nWtTalb","ChamanculoCS" ="CtlQF8Vac9k" ,"ChamanculoHG"="g0bRtxKVUVQ","JMCS"="pB4dqFQTJix",
                   "JMHG" = "yrfeiAhBKeO",  "Xipamanine"="sWChmRhN9eS")

# 10- Task names - Nomes dos estagios a executar durante os checks
task_check_consistency_1  <- "Verficar a integridade do ficheiro de importacao"
task_check_consistency_2  <- "Verificar se todos os dataElements do Ficheiro de Mapeamento existem no DHIS2"
task_check_consistency_3  <- "Buscar valores para cada indicador: "
task_4  <- " "


