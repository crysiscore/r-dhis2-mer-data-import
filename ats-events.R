

# Get data from DHIS CCU TRACKER 
program.id                      <- 'PuNhQ0F6I7H' #Aconselhamento e testagem em saude            
org.unit                        <- 'ebcn8hWYrg3' # CIDADE DE MAPUTO
distric.org.uni                 <- 'c1N79yeN7S2'
program.stage.id.registo.diario <- 'sNCq7QAZmMF' # Registo diario do ATS
program.stage.id.ligacao        <- 'buuvxzLEfWZ' # Ligacao Clinica 
program.stage.id.cpn            <- 'KGVOhPMAdag' # CPN


# DHIS API URL
# API: Pacientes endpoint

# API:DHIS2
dhis.base.url <- "https://mail.ccsaude.org.mz:5459/"
api.dhis.base.url <- "https://mail.ccsaude.org.mz:5459/"



#dhisLogin(dhis2.username,dhis2.password,dhis.base.url)



# Lista das US  da Cidade de Maputo
#  OrganizationUnit id= ebcn8hWYrg3 (Cidade de Maputo)
unidadesSanitarias <- getOrganizationUnits(api.dhis.base.url,org.unit)

# Todos data Elements do DHIS2
dataElements <- getDataElements(api.dhis.base.url)
dataElements$name <- as.character(dataElements$name)
dataElements$shortName <- as.character(dataElements$shortName)
dataElements$id <- as.character(dataElements$id)

#Program stages
programStages <- getProgramStages(api.dhis.base.url,program.id)
programStages$name <- as.character(programStages$name)
#programStages$description <- as.character(programStages$description)
programStages$id <- as.character(programStages$id)


# Get program enrollment: pi.dhis.base.url ,org.unit,program.id
enrollments <- getEnrollments(api.dhis.base.url ,org.unit,program.id)

# get TrackedInstances: api.dhis.base.url,program.id,org.unit

trackedInstances <- getTrackedInstances(api.dhis.base.url,program.id,org.unit)
