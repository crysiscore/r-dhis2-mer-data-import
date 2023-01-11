str_json <- toJSON(x = df_all_indicators , dataframe = 'rows', pretty = T)
# API:DHIS2 URLs

api_dhis_base_url <- "http://192.168.1.10:5400"
api_dhis_datasets <- 'https://mail.ccsaude.org.mz:5459/api/dataSets/'


datavalueset_template_dhis2_datim         <- getDhis2DatavalueSetTemplate(url.api.dhis.datasets = api_dhis_datasets, dataset.id = dataset_id_mer_datim)
