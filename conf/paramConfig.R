
# -- ---------------------------- Configuration parameters  ------------------------------ --

# Project location on server
# wd <- '/home/agnaldo/Git/ccs_datim_maping/'
wd <- getwd()
print(wd)

# Project Dir
# Uncomment the following line when deploying on Server
upload_dir <- paste0(wd,'/datim_uploads')

# 3- DHIS2 DATASET NAMES (DO NOT CHANGE)
mer_datasets_names            <- c("MER C&T"  = "ct", "MER ATS" = "ats" , "MER SMI" = "smi" , "MER PREVENTION"="prevention",
                                   "MER HEALTH SYSTEM"="hs","MER ATS COMMUNITY"="ats_community", "NON MER - MDS e Avaliacao de Retencao"="non_mer_mds")

# 4- CCS DHIS2 Datasets IDs (DO NOT CHANGE)
mer_datasets_ids              <- c("MER C&T"  = "WmHFZdWbzU2", "MER ATS" = "b2a0MuC3lb1" , "MER SMI" = "OQDQqOI7brV" , "MER PREVENTION"="JbLlGyAwQkd", 
                                   "MER HEALTH SYSTEM"="AAw69FykQil", "MER ATS COMMUNITY"="aWAxctvA9jY", "MER - DATIM FORM"="Z9agMHXo792",
                                   "NON MER - MDS e Avaliacao de Retencao"="LUsbbPX9hlO")

dataset_id_mer_ct             <- 'WmHFZdWbzU2'
dataset_id_mer_ats            <- 'b2a0MuC3lb1'
dataset_id_mer_prevention     <- 'JbLlGyAwQkd'
dataset_id_mer_smi            <- 'OQDQqOI7brV'
dataset_id_mer_hs             <- 'AAw69FykQil'
dataset_id_mer_ats_community  <- 'aWAxctvA9jY'
dataset_id_mer_datim          <- "Z9agMHXo792"
dataset_id_non_mer_mds        <- 'LUsbbPX9hlO'

# 5- Reporting Periods   
vec_reporting_periods <- list( "January 2022"= "202201","February 2022" = "202202", "March 2022"  ="202203","April 2022" = "202204",
                                   "May 2022" = "202205","June 2022" =  "202206","July 2022" =  "202207", "August 2022"  =  "202208",
                                   "September 2022" = "202209", "October 2022" ="202210",  "November 2022"="202211" ,"December 2022" = "202212",
                                  "January 2023"= "202301", "February 2023" ="202302", "March 2023"  = "202303", "April 2023" = "202304", 
                                  "May 2023" = "202305",  "June 2023" = "202306", "July 2023" =  "202307",  "August 2023"  = "202308",
                                  "September 2023" = "202309","October 2023" ="202310",  "November 2023"="202311" ,"December 2023" = "202312",
                                  "January 2024"= "202401","February 2024" = "202402", "March 2024"  ="202403","April 2024" = "202404",
                                  "May 2024" = "202405","June 2024" =  "202406","July 2024" =  "202407", "August 2024"  =  "202408",
                                  "September 2024" = "202409", "October 2024" ="202410",  "November 2024"="202411" ,"December 2024" = "202412")


vec_datim_reporting_periods <- list(
                                    "January - March 2023 (Q2)"= "2023Q1", "April - June 2023 (Q3)" ="2023Q2",
                                    "July - September 2023 (Q4)"="2023Q3", "October - December 2023 (Q1)"="2023Q4",
                                    "January - March 2024 (Q2)"= "2024Q1", "April - June 2024 (Q3)" ="2024Q2",
                                    "July - September 2024 (Q4)"="2024Q3", "October - December 2024 (Q1)"="2024Q4"
                                    #"January - March 2022 (Q2)"= "2022Q1", "April - June 2022 (Q3)" ="2022Q2",
                                    #"July - September 2022 (Q4)"="2022Q3", "October - December 2022 (Q1)"="2022Q4",
                                    )  

#IP Funding Mechanism ->   https://www.datim.org/api/sqlViews/fgUtV6e9YIX/data.html+css
funding_mechanism <- 160451  
#funding_mechanism_uid <-  'VGk8OiHSXM7'  

# 6- MER TEMPLATES -  Planilhas de mapeamento
excell_mapping_template_mer_prevention     <- 'MER PREVENTION.xlsx'
excell_mapping_template_mer_ct             <- 'MER CARE & TREATMENT.xlsx'
excell_mapping_template_mer_ats            <- 'MER ATS.xlsx'
excell_mapping_template_mer_smi            <- 'MER SMI.xlsx'
excell_mapping_template_mer_hs             <- 'MER HEALTH SYSTEM.xlsx' 
excell_mapping_template_mer_ats_community  <- 'MER ATS COMMUNITY.xlsx' 
excell_mapping_template_non_mer_mds        <- 'NON MER MAPPING MDS.xlsx'

# 7- DF Value templates (DO NOT CHANGE)
#vec_mer_dataset_valuetemplates_names <- c("datavalueset_template_dhis2_mer_ct","datavalueset_template_dhis2_mer_ats" ,"datavalueset_template_dhis2_mer_prevention",
#                                         "datavalueset_template_dhis2_mer_smi","datavalueset_template_dhis2_mer_hs","datavalueset_template_dhis2_mer_ats_community")

# 8- MER INDICATORS
# Nomes dos indicadores mapeados em cada planilha excell no ficheiro de  mapeamentos. 

vec_mer_ct_indicators          <- c('DSD TX NEW', 'DSD TX CURR',  'DSD TX RTT', 'DSD TX ML','DSD PMCT ART','DSD TX PVLS','DSD TX TB','DSD TB ART')
vec_mer_ats_indicators         <- c('DSD HTS TST','DSD HTS INDEX','DSD HTS SELF','DSD TB STAT')
vec_mer_smi_indicators         <- c('DSD PMTCT STAT','DSD PMTCT EID','DSD PMTCT HEI POS','DSD CXCA SCRN','DSD CXCA TX')
vec_mer_prevention_indicators  <- c('DSD PREP','DSD TB PREV','DSD GEND GBV', 'DSD FPINT SITE')
vec_mer_ats_community          <- c('DSD HTS TST COMMUNITY OTHER','DSD HTS INDEX COMMUNITY')
vec_mer_hs_indicators          <- c('LAB PTCQI','EMR SITE', 'FPINT', 'PMTCT FO')
# NON MER INDICATORS
vec_non_mer_mds                <- c('IM_ER', 'MDS')


# 9- Nomes das US (org. units) que aparecem nos sheets gerados automaticamente nos temlates de importacao: J. Mandlate e os respectivos IDs no DHIS
us_names_ids_dhis    <- list( "1Junho"="FTLV9nOnAFC","Albazine" ="z8g2CUKUMCF","Hulene" = "Ma6u8rJ3faa","MavalaneCS" ="wafWzemVbX4" , "MavalaneHG"="aqka8xA6c7u" ,
                           "Pescadores" ="XNYN71gD1ps" ,  "Romao" = "cEqnyE9ahXG" , "1Maio"="iv9D81uQSZc", "PCanico"="ehepVdZYP6u", "AltMae"="kt468XD802Y","CCivil"="hTu6J1VOBcZ", 
                           "HCMPed"="aMaDE2B3W0b","Malhangalene" ="DFudgV3AdHI", "Maxaquene" ="Dz4coB1P1l5","PCimento"="yGhwOKR4gBj","Porto"="DoyPc35A7zI", "Bagamoio"="aywqWn0Qkf8"
                           ,"HPI" = "QzORjiSM4Yz","Inhagoia"="EysXJHRv7xJ","MagoanineA"="o4HThkC2OEY","MTendas"="oKA7Ub02ze5", "Zimpeto"="KxezVOQ2TVR",
                           "Inhaca"="GJaIp0bKoXH","Catembe"="RYReGTxpYTF", "Incassane" ="MaU3nWtTalb","ChamanculoCS" ="CtlQF8Vac9k" ,"ChamanculoHG"="g0bRtxKVUVQ","JMCS"="pB4dqFQTJix",
                           "JMHG" = "yrfeiAhBKeO",  "Xipamanine"="sWChmRhN9eS", "Kamavota"="iOs7EQeuLLG","Kamaxakeni"="AVjKUWRgKBG", "Kampfumu"="PtWKKinaEXb","Kamubukwana"="at6Mv4Zw321",
                           "Kanyaka"="BFNOLjUjAoG", "Katembe"="CVwHv6utuLy","Nlhamankulu"="c1N79yeN7S2" )  

# 10- Task names - Nomes dos estagios a executar durante os checks
task_check_consistency_1  <- "Verficar a integridade do ficheiro de importacao"
task_check_consistency_2  <- "Verificar se todos os dataElements do Ficheiro de Mapeamento existem no DHIS2"
task_check_consistency_3  <- "Buscar valores para cada indicador: "




