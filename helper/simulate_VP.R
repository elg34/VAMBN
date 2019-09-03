simulate_VPs = function(real,res,fitted,iterative=TRUE,scr,mth,wl,bl,n=NA,rej=0.5){
  library(randomForest)
  library(randomForestSRC)
  library(bnlearn)
  
  n_VP=ifelse(is.na(n),NROW(real),n)
  
  # estimate the structure and parameters of the Bayesian network.
  #res = tabu(real, maxp=5, blacklist=bl,whitelist=wl,  score=scr) # assuming tabu was the best structure learning approach (currently it seems like for PPMI hc is better!)
  #fitted = bn.fit(res,real, method=mth) now done outside
  VP = c()
  iter = 1
  
  # loops until we have a full dataset of VPs (overshoots so data is not always < n_ppts)
  while(NROW(VP) < n_VP){
    cat("iteration = ", iter, "\n")
    
    # generate data (until no NAs in any variables)
    generatedDF = rbn(fitted, n = n_VP)
    comp<-F
    while (!comp){ # using mixed data sometimes results in NAs in the generated VPs. These VPs are rejected.
      generatedDF<-generatedDF[complete.cases(generatedDF),]
      gen<-n_VP-dim(generatedDF)[1]
      if (gen>0){
        generatedDF<-rbind(generatedDF,rbn(fitted, n = gen)) # draw virtual patients
      }else{
        comp<-T 
      }
    }
    
    # VPs are iteratively rejected if they have less than 50% chance to be classified as "real" in a network focussing on correctly classifying real ppts.
    if(iterative){
      y = factor(c(rep("original", NROW(real)), rep("generated", n_VP)))
      df = data.frame(y=y, x=rbind(real, generatedDF))
      fit = rfsrc(y ~ ., data=df, case.wt=c(rep(1,sum(y=="original")), rep(0.2*sum(y=="original")/sum(y=="generated"), sum(y=="generated"))))
      print(fit)
      
      DGz = predict(fit)$predicted[(NROW(df) - NROW(generatedDF) + 1):NROW(df), "original"]
      DGz = (DGz >rej)*1
      acceptedVPs = generatedDF[DGz == 1,]
    }
    else
      acceptedVPs = generatedDF
    VP = rbind.data.frame(VP, acceptedVPs)
    iter = iter + 1
    print(NROW(VP))
  }
  VP
}
