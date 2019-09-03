
######### merge all data into right directories
merge_data<-function(){
  # Dir
  data_out<-'data/data_out/'
  
  #(standalone)
  data_all<-readRDS(file = paste0(data_out,'data_all_imp.rds'))
  data_stalone<-list(data_all[['stalone_VIS00']],
                     data_all[['stalone_VIS02']],
                     data_all[['stalone_VIS04']],
                     data_all[['stalone_VIS06']],
                     data_all[['stalone_VIS08']])
  data_stalone<-data_stalone %>% reduce(merge, by = 'SUBJID')
  #(aux)
  data_aux<-readRDS('data/data_out/data_aux.rds')
  data_aux<-data_aux %>% reduce(merge, by = 'SUBJID')
  data_aux<-as.data.frame(lapply(data_aux,factor))
  
  #(meta)
  data_meta<-read.csv('data/HI-VAE/metaenc.csv')
  
  # merge all
  data<-list(data_meta,data_aux,data_stalone) %>% reduce(merge, by = 'SUBJID')
  
  #flag 0 var cols
  print(colnames(data)[-includeVar(data)])
  data<-data[includeVar(data)]
  
  data$SUBJID<-factor(data$SUBJID)
  # refactor all factor columns (so there are no empty levels)
  for(col in colnames(data)){
    if (is.factor(data[,col])|grepl('scode_',col)){
      data[,col]<-factor(data[,col])
    }else if (is.factor(data[,col])){
      data[,col]<-as.numeric(data[,col])
    }
  }
  
  name<-'data_final'
  saveRDS(data,paste0(data_out,name,'.rds'))
  return(data)
}
