library(shinydashboard)
library(shiny)
library(jsonlite)
library(dplyr)
library(readxl)
library(dipsaus)
library(shinyWidgets)
library(DT)
library(jsonlite)
library(dplyr)
library(fs)
library(shinyalert)
library(shinyjs)


source(file = 'paramConfig.R')     #  Carrega os paramentros 
setwd(wd)                          #  
source(file = 'misc_functions.R')  #  Ficheiro com diversas funcoes
source(file = 'credentials.R')     #  Variaveis de conexao do DHIS2
load( file = 'rdata.RData')        #  Ficheiro com DF que armazenam temporariamente os logs e algumas variaveis usadas no codigo


# Login to DHIS2
# dhisLogin(dhis2.username = dhis2.username,dhis2.password = dhis2.password,base.url = api_dhis_base_url )
# Gerar o template de importacao de dados para cada dataset: MER CT, MER SMI, MER ATS, MEER PREVENTION, MER HEALTH SYSTEMS do DHIS2
datavalueset_template_dhis2_mer_ct         <<- getDhis2DatavalueSetTemplate(url.api.dhis.datasets = api_dhis_datasets, dataset.id = dataset_id_mer_ct)
datavalueset_template_dhis2_mer_ats        <<- getDhis2DatavalueSetTemplate(url.api.dhis.datasets = api_dhis_datasets, dataset.id = dataset_id_mer_ats)
datavalueset_template_dhis2_mer_smi        <<- getDhis2DatavalueSetTemplate(url.api.dhis.datasets = api_dhis_datasets, dataset.id = dataset_id_mer_smi)
datavalueset_template_dhis2_mer_prevention <<- getDhis2DatavalueSetTemplate(url.api.dhis.datasets = api_dhis_datasets, dataset.id = dataset_id_mer_prevention)
datavalueset_template_dhis2_mer_hs         <<- getDhis2DatavalueSetTemplate(url.api.dhis.datasets = api_dhis_datasets, dataset.id = dataset_id_mer_hs)


#NOT RUN
#save(upload_history_empty, error_log_dhis_import,error_log_dhis_import_empty, log_execution , vec_us_names, file = '')
