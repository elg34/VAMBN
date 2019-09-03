compare_dists<-function(data,typecol,folder,conf.lev){
  gnames<-unique(data[,typecol])
  vnames<-colnames(data[,!grepl('type',colnames(data))])
  #alpha<-0.05/sum(sapply(vnames,function(x) !is.factor(data[,x])))
  alpha<-0.05/length(vnames)
  
  lv<-levels(factor(data[,typecol]))
  group.1<-subset(data,eval(parse(text = typecol))==lv[1])
  group.2<-subset(data,eval(parse(text = typecol))==lv[2])
  
  pvals<-NULL
  for (col in vnames){
    
    # ks if cont, chisq if cat
    pval = tryCatch({
      ifelse(
        is.factor(group.1[,col]),
        chisq.test(group.1[,col], group.2[,col], simulate.p.value = TRUE)$p.value,
        ks.boot(group.1[,col], group.2[,col])$ks.boot.pvalue
      )
    }, error = function(e) {
      print(e)
      NA # for when no instance of a level in factor
    })
    
    dat<-data[,grepl(paste0(col,'$|type'),colnames(data))]
    sig<-ifelse(pval<alpha,'*','N.S.')
    if (is.numeric(data[,col])){
      dv1<-group.1[,col]
      dv2<-group.2[,col]
      if ((group.1$type[1]!='real')&(group.1$type[1]!='decRP'))
        error('Check variable levels!')
      z<-qnorm((1-conf.lev)/2,lower.tail = F)
      conf1<-c(mean(dv1,na.rm = T) - z * sd(dv1,na.rm = T), mean(dv1,na.rm = T) + z * sd(dv1,na.rm = T))
      conf2<-c(mean(dv2,na.rm = T) - z * sd(dv2,na.rm = T), mean(dv2,na.rm = T) + z * sd(dv2,na.rm = T))
      plot<-ggplot(dat, aes(x=eval(parse(text = col)),fill=type))+geom_density(alpha=.2)+xlab(col)+ylab('density')+geom_vline(xintercept=c(conf1[1], mean(dv1,na.rm = T), conf1[2]), linetype='dashed',color=c('red','red','red'))+geom_vline(xintercept=c(conf2[1], mean(dv2,na.rm = T), conf2[2]), linetype='dotted',color=c('blue','blue','blue'))#+ggtitle(paste('Permutation Pval:',pval,'Alpha:',signif(alpha,digits = 3),'Sig:',sig))
    }else{
      gd <- dat %>% group_by(type) %>% count
      plot<-ggplot(gd, aes(x=eval(parse(text = col)),y=freq,fill=type))+geom_bar(position="dodge", stat="identity")+scale_fill_brewer(palette="Dark2")+xlab(col)+ylab('Count')#+ggtitle(paste('Permutation Pval:',pval,'Alpha:',signif(alpha,digits = 3),'Sig:',sig))
    }
    pvals<-c(pvals,pval)
    ggsave(paste0(folder,col,'.png'), plot, device = "png", width=7.26, height = 4.35)
  }
  hist(pvals,breaks=250)
  abline(v=alpha,col="red")
  abline(v=0.05,col="blue")
  print(paste('Corrected: Significant difference in',length(pvals[pvals<alpha]),'out of',length(pvals)))
  print(paste('Unorrected: Significant difference in',length(pvals[pvals<0.05]),'out of',length(pvals)))
}

compare_dists_paper<-function(data,typecol,folder){
  gnames<-unique(data[,typecol])
  vnames<-colnames(data[,!grepl('type',colnames(data))])
  
  lv<-levels(factor(data[,typecol]))
  group.1<-subset(data,eval(parse(text = typecol))==lv[1])
  group.2<-subset(data,eval(parse(text = typecol))==lv[2])
  group.3<-subset(data,eval(parse(text = typecol))==lv[3])
  
  print(paste0('1: ',lv[1],' 2: ',lv[2],' 3: ',lv[3]))
  
  pvals<-NULL
  for (col in vnames){
    print(col)
    dat<-data[,grepl(paste0(col,'$|type'),colnames(data))]
    if (is.numeric(data[,col])){
      dv1<-group.1[,col]
      dv2<-group.2[,col]
      dv3<-group.3[,col]
      stats<-matrix(c(lv[1],round(mean(dv1,na.rm=T),2),round(sd(dv1,na.rm=T),2),round(quantile(dv1,na.rm=T)['25%'],2),round(median(dv1,na.rm=T),2),round(quantile(dv1,na.rm=T)['75%'],2),
                      lv[2],round(mean(dv2,na.rm=T),2),round(sd(dv2,na.rm=T),2),round(quantile(dv2,na.rm=T)['25%'],2),round(median(dv2,na.rm=T),2),round(quantile(dv2,na.rm=T)['75%'],2),
                      lv[3],round(mean(dv3,na.rm=T),2),round(sd(dv3,na.rm=T),2),round(quantile(dv3,na.rm=T)['25%'],2),round(median(dv3,na.rm=T),2),round(quantile(dv3,na.rm=T)['75%'],2)
      ),ncol=6,byrow=TRUE)
      colnames(stats) <- c("Type","Mean","SD","25%","Median","75%")
      plot1<-ggplot(dat, aes(x=type,y=eval(parse(text = col)),fill=type))+
        geom_violin(position=position_dodge(1)) + 
        geom_boxplot(position=position_dodge(1),width=0.05) +      
        xlab('type')+ylab(col)+theme(legend.position="None",axis.title.x=element_blank())
      gr<-grey.colors(3)
      tt3 <- ttheme_minimal(
        core=list(bg_params = list(fill = c(gr[2],gr[3],gr[2]), col=NA),
                  fg_params=list(fontface=3)))
      plot<-grid.arrange(plot1,tableGrob(stats,theme=tt3),ncol=1, 
                         widths=unit(15,"cm"),
                         heights=unit(c(8,3), c("cm", "cm")))
    }else{
      gd <- dat %>% group_by(type) %>% count
      plot<-ggplot(gd, aes(x=eval(parse(text = col)),y=freq,fill=type))+geom_bar(position="dodge", stat="identity")+scale_fill_brewer(palette="Dark2")+xlab(col)+ylab('Count')#+ggtitle(paste('Permutation Pval:',pval,'Alpha:',signif(alpha,digits = 3),'Sig:',sig))
    }
    ggsave(paste0(folder,col,'.png'), plot, device = "png", width=7.26, height = 4.35)
    ggsave(paste0(folder,col,'.eps'), plot, device = "eps", width=7.26, height = 4.35)
  }
}
