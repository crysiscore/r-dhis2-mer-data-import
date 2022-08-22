#--      required libraries                    --#
require(curl)
require(tidyr)
require(jsonlite)

wd <- "/home/agnaldo/Git/ccs_datim_maping/"
setwd(wd)
source('misc_functions.R')

# DHIS urls
login.base.url<-"https://mail.ccsaude.org.mz:5459/dhis-web-commons/security/login.action?"
api_url<-"https://mail.ccsaude.org.mz:5459/"
username<-"mea.teste"
password<-'Manaca123!'


# Data sets
org_unit <- 'ebcn8hWYrg3'               # CIDADE DE MAPUTO
mer_ct_dataset_id <- 'WmHFZdWbzU2'


dhisLogin(username,password,login.base.url)

# Lista das US  da Cidade de Maputo
# OrganizationUnit id= ebcn8hWYrg3 (Cidade de Maputo)
unidadesSanitarias <- getOrganizationUnits(api_url,org_unit)

# Data set e seus dataelements
mer_ct_data_elements <- getDataSetDataElements(base.url = api_url,dataset.id = mer_ct_dataset_id)


