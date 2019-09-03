############# README
# The current file was used to format PPMI data.
# To adjust for your own data, save out the variables you need in a list of dataframes,
# comprising of individual visit dataframes (including subject id)
##############

rm(list=ls())
load('compare/allVisitData_and_PatientData.RData')
data<-allVisitData_and_PatientData
data$SUBJID<-factor(1:dim(data)[1])

# change visit names
colnames(data) = sub("\\.BL", "_VIS00", colnames(data))
colnames(data) = sub("\\.V01", "_VIS01", colnames(data))
colnames(data) = sub("\\.V02", "_VIS02", colnames(data))
colnames(data) = sub("\\.V03", "_VIS03", colnames(data))
colnames(data) = sub("\\.V04", "_VIS04", colnames(data))
colnames(data) = sub("\\.V05", "_VIS05", colnames(data))
colnames(data) = sub("\\.V06", "_VIS06", colnames(data))
colnames(data) = sub("\\.V07", "_VIS07", colnames(data))
colnames(data) = sub("\\.V08", "_VIS08", colnames(data))
colnames(data) = sub("\\.V09", "_VIS09", colnames(data))
colnames(data) = sub("\\.V10", "_VIS10", colnames(data))
colnames(data) = sub("\\.V11", "_VIS11", colnames(data))

# Replace INF value with NA
do.call(data.frame,lapply(data, function(x) replace(x, is.infinite(x),NA)))

### extract variable groups
# medical history
# nonmotor
# Biological
# Patient
# updrs 1,2,3,total
# Imaging*
# RBD*
# SA: ENROL AGE, CSF, GENDER, SIMP. GENDER
colnames(data)[grepl('Simple|ENROL',colnames(data))]<-paste0(colnames(data)[grepl('Simple|ENROL',colnames(data))],'_VIS00')
for(col in colnames(data)){
  if (grepl('GENDER|Simple|SUBJID|QUIP',col))
    data[,col]<-factor(data[,col])
}
medh<-data[,grepl('SUBJID|MedicalHistory',colnames(data))]
nonm<-data[,grepl('SUBJID|NonMotor',colnames(data))]
biol<-data[,grepl('SUBJID|Biological|CSF',colnames(data))&!grepl('synucl',colnames(data))]
pat_demo<-data[,grepl('SUBJID|EDUCYRS|HANDED|GENDER|HISPLAT|RAINDALS|RAASIAN|RABLACK|RAHAWOPI|RAWHITE|RANOS|Origin',colnames(data))]
for(col in colnames(pat_demo)){
  if (!grepl('SUBJID|EDUCYRS',col))
    pat_demo[,col]<-factor(pat_demo[,col])
}
colnames(pat_demo)<-gsub('Patient_','PatDemo_',colnames(pat_demo))
pat_hist<-data[,grepl('SUBJID|Patient_',colnames(data))]
pat_hist<-pat_hist[,!grepl('EDUCYRS|AGE|GENDER|HANDED|GENDER|HISPLAT|RAINDALS|RAASIAN|RABLACK|RAHAWOPI|RAWHITE|RANOS|Origin',colnames(pat_hist))]
colnames(pat_hist)<-gsub('Patient_','PatPDHist_',colnames(pat_hist))
colnames(pat_hist)[colnames(pat_hist)=='PatPDHist_KIDSPD']<-'PatPDHist_KIDSNUMPD'
pdrem<-colnames(pat_hist[,!grepl('SUBJID|PD$',colnames(pat_hist))])
pat_hist=pat_hist[,!(colnames(pat_hist)%in%pdrem)]
for(col in colnames(pat_hist)){
  if (!grepl('SUBJID',col))
    pat_hist[,col]<-factor(pat_hist[,col])
}
updrs<-data[,grepl('SUBJID|UPDRS',colnames(data))]
SA<-data[,grepl('SUBJID|RBD|Imaging|ENROL|synucl|Gender',colnames(data))]
colnames(SA) = gsub('Patient_','',colnames(SA))
colnames(SA) = sub('RBD_','',colnames(SA))
colnames(SA)[colnames(SA)!='SUBJID'] = paste0('SA_',colnames(SA)[colnames(SA)!='SUBJID'])

data_all<-list('MedicalHistory_VIS00'=medh[,grepl('SUBJID|_VIS00',colnames(medh))],
               'MedicalHistory_VIS01'=medh[,grepl('SUBJID|_VIS01',colnames(medh))],
               'MedicalHistory_VIS02'=medh[,grepl('SUBJID|_VIS02',colnames(medh))],
               'MedicalHistory_VIS03'=medh[,grepl('SUBJID|_VIS03',colnames(medh))],
               'MedicalHistory_VIS04'=medh[,grepl('SUBJID|_VIS04',colnames(medh))],
               'MedicalHistory_VIS05'=medh[,grepl('SUBJID|_VIS05',colnames(medh))],
               'MedicalHistory_VIS06'=medh[,grepl('SUBJID|_VIS06',colnames(medh))],
               'MedicalHistory_VIS07'=medh[,grepl('SUBJID|_VIS07',colnames(medh))],
               'MedicalHistory_VIS08'=medh[,grepl('SUBJID|_VIS08',colnames(medh))],
               'MedicalHistory_VIS09'=medh[,grepl('SUBJID|_VIS09',colnames(medh))],
               'MedicalHistory_VIS10'=medh[,grepl('SUBJID|_VIS10',colnames(medh))],
               'MedicalHistory_VIS11'=medh[,grepl('SUBJID|_VIS11',colnames(medh))],
               'NonMotor_VIS00'=nonm[,grepl('SUBJID|_VIS00',colnames(nonm))],
               'NonMotor_VIS02'=nonm[,grepl('SUBJID|_VIS02',colnames(nonm))],
               'NonMotor_VIS04'=nonm[,grepl('SUBJID|_VIS04',colnames(nonm))],
               'NonMotor_VIS06'=nonm[,grepl('SUBJID|_VIS06',colnames(nonm))],
               'NonMotor_VIS08'=nonm[,grepl('SUBJID|_VIS08',colnames(nonm))],
               'NonMotor_VIS10'=nonm[,grepl('SUBJID|_VIS10',colnames(nonm))],
               'Biological_VIS00'=biol[,grepl('SUBJID|_VIS00',colnames(biol))],
               'Biological_VIS08'=biol[,grepl('SUBJID|_VIS08',colnames(biol))],
               'PatDemo_VIS00'=pat_demo,
               'PatPDHist_VIS00'=pat_hist,
               'UPDRS_VIS00'=updrs[,grepl('SUBJID|_VIS00',colnames(updrs))],
               'UPDRS_VIS01'=updrs[,grepl('SUBJID|_VIS01',colnames(updrs))],
               'UPDRS_VIS02'=updrs[,grepl('SUBJID|_VIS02',colnames(updrs))],
               'UPDRS_VIS03'=updrs[,grepl('SUBJID|_VIS03',colnames(updrs))],
               'UPDRS_VIS04'=updrs[,grepl('SUBJID|_VIS04',colnames(updrs))],
               'UPDRS_VIS05'=updrs[,grepl('SUBJID|_VIS05',colnames(updrs))],
               'UPDRS_VIS06'=updrs[,grepl('SUBJID|_VIS06',colnames(updrs))],
               'UPDRS_VIS07'=updrs[,grepl('SUBJID|_VIS07',colnames(updrs))],
               'UPDRS_VIS08'=updrs[,grepl('SUBJID|_VIS08',colnames(updrs))],
               'UPDRS_VIS09'=updrs[,grepl('SUBJID|_VIS09',colnames(updrs))],
               'UPDRS_VIS10'=updrs[,grepl('SUBJID|_VIS10',colnames(updrs))],
               'UPDRS_VIS11'=updrs[,grepl('SUBJID|_VIS11',colnames(updrs))],
               'stalone_VIS00'=SA[,grepl('SUBJID|_VIS00',colnames(SA))],
               'stalone_VIS02'=SA[,grepl('SUBJID|_VIS02',colnames(SA))],
               'stalone_VIS04'=SA[,grepl('SUBJID|_VIS04',colnames(SA))],
               'stalone_VIS06'=SA[,grepl('SUBJID|_VIS06',colnames(SA))],
               'stalone_VIS08'=SA[,grepl('SUBJID|_VIS08',colnames(SA))]
               )
saveRDS(data_all,"data/data_condensed.rds")
