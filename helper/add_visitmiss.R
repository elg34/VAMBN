add_visitmiss<-function(discdata){
  discdata$visitmiss_VIS01<-factor(ifelse(apply(discdata[,grepl('AUX_',colnames(discdata))&grepl('_VIS01',colnames(discdata))],1,function(x) (all(x==1))),1,0))
  discdata$visitmiss_VIS02<-factor(ifelse(apply(discdata[,grepl('AUX_',colnames(discdata))&grepl('_VIS02',colnames(discdata))],1,function(x) (all(x==1))),1,0))
  discdata$visitmiss_VIS03<-factor(ifelse(apply(discdata[,grepl('AUX_',colnames(discdata))&grepl('_VIS03',colnames(discdata))],1,function(x) (all(x==1))),1,0))
  discdata$visitmiss_VIS04<-factor(ifelse(apply(discdata[,grepl('AUX_',colnames(discdata))&grepl('_VIS04',colnames(discdata))],1,function(x) (all(x==1))),1,0))
  discdata$visitmiss_VIS05<-factor(ifelse(apply(discdata[,grepl('AUX_',colnames(discdata))&grepl('_VIS05',colnames(discdata))],1,function(x) (all(x==1))),1,0))
  discdata$visitmiss_VIS06<-factor(ifelse(apply(discdata[,grepl('AUX_',colnames(discdata))&grepl('_VIS06',colnames(discdata))],1,function(x) (all(x==1))),1,0))
  discdata$visitmiss_VIS07<-factor(ifelse(apply(discdata[,grepl('AUX_',colnames(discdata))&grepl('_VIS07',colnames(discdata))],1,function(x) (all(x==1))),1,0))
  discdata$visitmiss_VIS08<-factor(ifelse(apply(discdata[,grepl('AUX_',colnames(discdata))&grepl('_VIS08',colnames(discdata))],1,function(x) (all(x==1))),1,0))
  discdata$visitmiss_VIS09<-factor(ifelse(apply(discdata[,grepl('AUX_',colnames(discdata))&grepl('_VIS09',colnames(discdata))],1,function(x) (all(x==1))),1,0))
  discdata$visitmiss_VIS10<-factor(ifelse(apply(discdata[,grepl('AUX_',colnames(discdata))&grepl('_VIS10',colnames(discdata))],1,function(x) (all(x==1))),1,0))
  discdata$visitmiss_VIS11<-factor(ifelse(apply(discdata[,grepl('AUX_',colnames(discdata))&grepl('_VIS11',colnames(discdata))],1,function(x) (all(x==1))),1,0))
  d1<-as.data.frame(t(discdata[,(grepl('AUX_',colnames(discdata))&grepl('_VIS01',colnames(discdata)))|grepl('visitmiss_VIS00',colnames(discdata))]))
  d2<-as.data.frame(t(discdata[,(grepl('AUX_',colnames(discdata))&grepl('_VIS02',colnames(discdata)))|grepl('visitmiss_VIS00',colnames(discdata))]))
  d3<-as.data.frame(t(discdata[,(grepl('AUX_',colnames(discdata))&grepl('_VIS03',colnames(discdata)))|grepl('visitmiss_VIS00',colnames(discdata))]))
  d4<-as.data.frame(t(discdata[,(grepl('AUX_',colnames(discdata))&grepl('_VIS04',colnames(discdata)))|grepl('visitmiss_VIS00',colnames(discdata))]))
  d5<-as.data.frame(t(discdata[,(grepl('AUX_',colnames(discdata))&grepl('_VIS05',colnames(discdata)))|grepl('visitmiss_VIS00',colnames(discdata))]))
  d6<-as.data.frame(t(discdata[,(grepl('AUX_',colnames(discdata))&grepl('_VIS06',colnames(discdata)))|grepl('visitmiss_VIS00',colnames(discdata))]))
  d7<-as.data.frame(t(discdata[,(grepl('AUX_',colnames(discdata))&grepl('_VIS07',colnames(discdata)))|grepl('visitmiss_VIS00',colnames(discdata))]))
  d8<-as.data.frame(t(discdata[,(grepl('AUX_',colnames(discdata))&grepl('_VIS08',colnames(discdata)))|grepl('visitmiss_VIS00',colnames(discdata))]))
  d9<-as.data.frame(t(discdata[,(grepl('AUX_',colnames(discdata))&grepl('_VIS09',colnames(discdata)))|grepl('visitmiss_VIS00',colnames(discdata))]))
  d10<-as.data.frame(t(discdata[,(grepl('AUX_',colnames(discdata))&grepl('_VIS10',colnames(discdata)))|grepl('visitmiss_VIS00',colnames(discdata))]))
  d11<-as.data.frame(t(discdata[,(grepl('AUX_',colnames(discdata))&grepl('_VIS11',colnames(discdata)))|grepl('visitmiss_VIS00',colnames(discdata))]))
  rm1<-rownames(d1)[duplicated(d1,fromLast=TRUE)]
  rm2<-rownames(d2)[duplicated(d2,fromLast=TRUE)]
  rm3<-rownames(d3)[duplicated(d3,fromLast=TRUE)]
  rm4<-rownames(d4)[duplicated(d4,fromLast=TRUE)]
  rm5<-rownames(d5)[duplicated(d5,fromLast=TRUE)]
  rm6<-rownames(d6)[duplicated(d6,fromLast=TRUE)]
  rm7<-rownames(d7)[duplicated(d7,fromLast=TRUE)]
  rm8<-rownames(d8)[duplicated(d8,fromLast=TRUE)]
  rm9<-rownames(d9)[duplicated(d9,fromLast=TRUE)]
  rm10<-rownames(d10)[duplicated(d10,fromLast=TRUE)]
  rm11<-rownames(d11)[duplicated(d11,fromLast=TRUE)]
  rm<-c(rm1,rm2,rm3,rm4,rm5,rm6,rm7,rm8,rm9,rm10,rm11) # orphaned nodes are those whose immediate parent AUX is identical to the visitmiss at that visit
  return list(data=discdata,rm=rm)
  
}