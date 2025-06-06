
# -- ---------------------------- Configuration parameters  ------------------------------ --

# Project location on server
# wd <- '/home/agnaldo/Git/ccs_datim_maping/'
wd <- getwd()
print(wd)


# Project Dir
# Uncomment the following line when deploying on Server
upload_dir <- paste0(wd,'/datim_uploads')

# 3- DHIS2 DATASET NAMES 
# Read data from excell
mer_datasets_names <- readxl::read_xlsx(path = paste0(wd,'/conf/paramConfig.xlsx'), sheet = 'mer_datasets_names', col_names = TRUE)
mer_datasets_names <- setNames(mer_datasets_names$label, mer_datasets_names$name)


# 4- CCS DHIS2 Datasets IDs
# Read data from excell
mer_datasets_ids <- readxl::read_xlsx(path = paste0(wd,'/conf/paramConfig.xlsx'), sheet = 'mer_datasets_ids', col_names = TRUE)
mer_datasets_ids <- setNames(mer_datasets_ids$id, mer_datasets_ids$name)


# 4- CCS DHIS2 Datasets IDs
tmp_df <- readxl::read_xlsx(path = paste0(wd,'/conf/paramConfig.xlsx'), sheet = 'mer_datasets_id', col_names = TRUE)
for (i in 1:nrow(tmp_df)){
  assign(x = tmp_df$name[i], value = tmp_df$id[i], envir = .GlobalEnv)
}


# 5- Reporting Periods
# Read data from excel
vec_reporting_periods <- readxl::read_xlsx(path = paste0(wd,'/conf/paramConfig.xlsx'), sheet = 'vec_reporting_periods', col_names = TRUE)
vec_reporting_periods <- as.list(setNames(as.character(vec_reporting_periods$code), vec_reporting_periods$period))

vec_datim_reporting_periods <- readxl::read_xlsx(path = paste0(wd,'/conf/paramConfig.xlsx'), sheet = 'vec_datim_reporting_periods', col_names = TRUE)
vec_datim_reporting_periods <- as.list(setNames(as.character(vec_datim_reporting_periods$code), vec_datim_reporting_periods$period))


#IP Funding Mechanism ->   https://www.datim.org/api/sqlViews/fgUtV6e9YIX/data.html+css
funding_mechanism <- readxl::read_xlsx(path = paste0(wd,'/conf/paramConfig.xlsx'), sheet = 'funding_mechanism', col_names = TRUE)

for ( f in 1:nrow(funding_mechanism) ){
  assign(x = funding_mechanism$name[f], value = funding_mechanism$code[f], envir = .GlobalEnv)
}


# 6- MER TEMPLATES 
excell_mapping_template <- readxl::read_xlsx(path = paste0(wd,'/conf/paramConfig.xlsx'), sheet = 'excell_mapping_template', col_names = TRUE)

for (i in 1:nrow(excell_mapping_template)){
  assign(x =excell_mapping_template$template_name[i], value = excell_mapping_template$file_name[i], envir = .GlobalEnv)
}


# 8- MER INDICATORS
# Nomes dos indicadores mapeados em cada planilha excell no ficheiro de  mapeamentos. 

df_tmp <- readxl::read_xlsx(path = paste0(wd,'/conf/paramConfig.xlsx'), sheet = 'vec_mer_indicators', col_names = TRUE)

for (i in 1:nrow(df_tmp)){
   # for each value in the column value, extract each separated by comma and assign add to a vector named vec_value
   vec_value <- unlist(strsplit(df_tmp$value[i], ","))
   assign(x = df_tmp$name[i], value = vec_value, envir = .GlobalEnv)
}


# 9- Nomes das US (org. units) que aparecem nos sheets gerados automaticamente nos temlates de importacao: J. Mandlate e os respectivos IDs no DHIS2

maputo_us_names_ids_dhis <- readxl::read_xlsx(path = paste0(wd,'/conf/paramConfig.xlsx'), sheet = 'mpt_us_names_ids_dhis', col_names = TRUE)
gaza_us_names_ids_dhis   <- readxl::read_xlsx(path = paste0(wd,'/conf/paramConfig.xlsx'), sheet = 'gaza_us_names_ids_dhis ', col_names = TRUE)
                                            
maputo_us_names_ids_dhis <- as.list(setNames(maputo_us_names_ids_dhis$code, maputo_us_names_ids_dhis$name))
gaza_us_names_ids_dhis   <-  as.list(setNames(gaza_us_names_ids_dhis$code, gaza_us_names_ids_dhis$name))



# 10- Task names - Nomes dos estagios a executar durante os checks
task_check_consistency_1  <- "Verficar a integridade do ficheiro de importacao"
task_check_consistency_2  <- "Verificar se todos os dataElements do Ficheiro de Mapeamento existem no DHIS2"
task_check_consistency_3  <- "Buscar valores para cada indicador: "




