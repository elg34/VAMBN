save_py<-function(data,datan,data_out_py,pt){
  
  pt<-data$SUBJID
  data$SUBJID<-NULL
  
  # scale data that goes into the autoencoders
  for (col in colnames(data)){
    if (!is.factor(data[,col])){
      data[,col]<-as.numeric(scale(data[,col]))
    }
  }
  
  # dummy code factors for autoencoders
  if (!grepl('stalone', datan)) # stalone has only one categorical var! should make code nicer here
    data<-make_dummy(data)
  
  # remove bad data
  data=data[,includeVar(data)]
  data=data[,rmMiss(data)]
  
  # make categorical and continuous subcategories
  data$SUBJID <- pt
  data_cat<-data[,sapply(colnames(data),function(x) is.factor(data[,x]))]
  data_cont<-data[,sapply(colnames(data),function(x) !is.factor(data[,x]))]
  data_cont$SUBJID<-data$SUBJID
  
  # save out for python/autoencoders
  write.csv(data,paste0(data_out_py,datan,'.csv'),row.names = F)
  if ((NCOL(data_cat)>1) & !grepl('stalone', datan))
    write.csv(data_cat,paste0(data_out_py,'cat_',datan,'.csv'),row.names = F)
  if ((NCOL(data_cont)>1) & !grepl('stalone', datan))
    write.csv(data_cont,paste0(data_out_py,'cont_',datan,'.csv'),row.names = F)
  
}