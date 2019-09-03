######### Add small amount of noise to AUX=1 data (constant otherwise)
addnoise<- function(dat,noise){
  rm=c()
  for (col in colnames(dat)){
    if(!is.factor(dat[,col]) & (any(sapply(colnames(dat),function(x) paste0('AUX_',gsub('zcode_|scode_','',col))==x)))){
      daux<-dat[,sapply(colnames(dat),function(x) paste0('AUX_',gsub('zcode_|scode_','',col))==x)]
      if (is.na(sd(dat[daux==1,col]))|sd(dat[daux==1,col])==0){
        if (length(dat[daux==1,col])==1){
          print(paste(col,'has only one missing data point! Removing AUX!'))
          rm<-c(rm,paste0('AUX_',gsub('zcode_|scode_','',col)))
        }else{
          dat[,col]<-ifelse(daux==1,dat[daux==1,col]+rnorm(length(dat[daux==1,col]),0,sd(dat[,col], na.rm = T)*noise),dat[,col])
        }
      }
    }
  }
  if (length(rm)==0){
    return(dat)
  }else{
    return(dat[,-which(colnames(dat) %in% rm)])
  }
}