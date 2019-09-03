######### return dataframe with NA's filles with either mean+noise or most frequent bin
fillna<- function(dat){
  for (col in colnames(dat)){
    if (!is.factor(dat[,col])){
      dat[,col]<-ifelse(is.na(dat[,col]),mean(dat[,col],na.rm = T),dat[,col])
    }else{
      if (any(is.na(dat[,col]))){
        ll<-data.frame(table(data[,col]))
        dat[is.na(dat[,col]),col]<-ll[order(ll$Freq,decreasing=T),1][1]
      }
    }
  }
  return(dat)
}
