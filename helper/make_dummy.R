######### return binary column names
binCol <- function(dat) {
  out <- lapply(colnames(dat), function(x) length(levels(factor(dat[,x])))==2)
  unlist(out)
}

######### create dummy variables for factors
make_dummy<-function(x){
  library(dummies)
  factor.data = x[,which(sapply(x,class) == 'factor')]
  for (cols in colnames(factor.data)[binCol(factor.data)]){
    levels(factor.data[,cols])<-c('0','1')
  }
  if(length(factor.data) != 0 ){
    factor.data.dummy <-dummy.data.frame(factor.data,names=colnames(factor.data)[!binCol(factor.data)], dummy.class="ALL" , sep = "::")
    factor.data.dummy <-as.data.frame(lapply(factor.data.dummy,factor))
    numeric.data = x[,-c(which(colnames(x) %in% colnames(factor.data)))]
    if(dim(factor.data.dummy)[2]!=0){
      xxdata = cbind( numeric.data, factor.data.dummy)
    }else{
      xxdata=cbind( numeric.data,as.numeric(x[,which(sapply(x,class) == 'factor')]))
    }
  }else{
    xxdata = x
  }
}