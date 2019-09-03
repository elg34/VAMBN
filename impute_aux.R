############# README
# For HI-VAE there is no actual imputation, just formatting and saveout of auxiliary variables and HIVAE input data.
# Before this, run the R files clean_format.R->impute_aux.R (scripts with fixed settings) to get the data into the right format.
# After this, run the autoencoder jupyter notebook for HIVAE training
##############

rm(list=ls())
library(missForest)
source('helper/make_dummy.R') # create dummies for categorical variables
source('helper/clean_help.R') # check for constant variables
source('helper/fill_na.R') # fill na with mean or most frequent cat
data_out<-'data/data_out/'
data_out_py<-'data/HI-VAE/data_python/'

###################### Imputation & AUX
data_all<-readRDS(file = paste0("data/data_condensed.rds"))
data_aux=list()
for (datan in names(data_all)){ # for every variable group

  # load data & remove SUBJID
  data<-data_all[[datan]]
  pt<-data$SUBJID
  data$SUBJID<-NULL

  # remove variables with too much missing data/constant values - don't do this for standalones, as these are assumed to
  # be deliberately included
  if (!grepl('stalone_', datan)){
    # remove bad data
    data=data[,includeVar(data)]
    data=data[,rmMiss(data)]
  }

  ###################### AUX variables

  # make AUX columns and save in separate list (with SUBJID)
  nms<-colnames(data)
  if (grepl('stalone', datan)){
    dataux<-as.data.frame(sapply(as.data.frame(is.na(data)), as.numeric))
    dataux<-as.data.frame(sapply(dataux,factor))
    colnames(dataux)<-paste('AUX',nms,sep='_')
  }else{
    dataux<-data.frame(factor(apply(data,1,function(x) as.numeric(all(is.na(x))))))
    colnames(dataux)<-paste('AUX',datan,sep='_')
  }

  # update AUX list
  dataux$SUBJID<-pt
  data_aux[[datan]]<-dataux

  ###################### Imputation
  print(datan)
  if (grepl('stalone', datan))
    data<-fillna(data) # if standalone data, mean and most frequent class imputation

  if (!grepl('stalone', datan)){
    # remove bad data
    data=data[,includeVar(data)]
    data=data[,rmMiss(data)]
  }

  # add ppt variable and update data list
  data$SUBJID <- pt
  data_all[[datan]]<-data

  # save out csv's of scaled continupous and dummy coded categorical data for autoencoders
  pt<-data$SUBJID
  data$SUBJID<-NULL

  # it doesnt like strings, save level number
  for (col in colnames(data)){
    if (is.factor(data[,col])){
      if((any(is.na(as.numeric(levels(data[,col])))))&grepl('PatDemo_|PatPDHist',datan))
        levels(data[,col])<-1:length(levels(data[,col]))
    }
  }

  #missing write
  if (!grepl('stalone', datan))
    write.table(which(is.na(data), arr.ind=TRUE),paste0(data_out_py,datan,'_missing.csv'),sep=',',row.names = F,col.names = F,quote=F)

  #data write
  if (!grepl('stalone', datan))
    write.table(data,paste0(data_out_py,datan,'.csv'),sep=',',row.names = F,col.names = F,quote=F, na = "NaN")

  write.table(as.character(pt),paste0('data/HI-VAE/python_names/',datan,'_subj.csv'),sep=',',row.names = F,col.names = T,quote=T, na = "NaN")
  write.table(colnames(data),paste0('data/HI-VAE/python_names/',datan,'_cols.csv'),sep=',',row.names = F,col.names = T,quote=T, na = "NaN")

}

# save all
saveRDS(data_all, file = paste0(data_out,'data_all_imp.rds'))
saveRDS(data_aux, file = paste0(data_out,'data_aux.rds'))

library(beepr)
beep()
