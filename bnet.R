############# README
# This file runs the Bayesian network and saves out VPs
#############

############################
############################ Dependencies and helper functions
############################
rm(list=ls())
library(tidyverse)
library(arules)
library(mclust)
library(rpart)
library(bnlearn)
library(parallel)
# general helpers
source('helper/plot_bn.R')
source('helper/clean_help.R')
source('helper/simulate_VP.R')
source('helper/save_VPmisslist.R')
# study specific helpers
source('helper/merge_data.R')
source('helper/addnoise.R')
source('helper/add_visitmiss.R')
source('helper/make_bl_wl_PPMI.R')

############################
############################ Settings and preprocessing
############################

# Name output files
name<-'main'
data_out<-paste0('data/data_out/',name)
scr<-"bic-cg" # BN score
mth<-"mle" # BN method

# Load data & remaining formatting of standalone
data<-merge_data() # merge imputed standalone and zcodes from HIVAE

# remove subject variable
pt<-data$SUBJID
data$SUBJID<-NULL

# add noise to the imputed/constant levels of continuous variables, prevents error in the BN due to singular data
discdata<-addnoise(data,0.01)

# Add parents for AUX variables
# This node represents whether a whole visit is missing for a participant
# AUX variables will be connected through these and it will account for their high correlation
# AUX variables that are identical to the visitmiss variables will be removed and its child node connected directly to the visitmiss variable at that visit
out<-add_visitmiss(discdata)
discdata<-out[['data']]
rm<-out[['rm']]
discdata<-discdata[ , !(names(discdata) %in% rm)]
# remove AUX that are almost identical to visitmiss nodes
lowaux<-discdata[,grepl('AUX_',colnames(discdata))&!(colnames(discdata) %in% rm)]
lowaux<-colnames(lowaux)[sapply(colnames(lowaux),function(x) sum(as.numeric(as.character(lowaux[,x])))<=5)]
discdata<-discdata[ , !(names(discdata) %in% lowaux)]
orphans<-gsub('AUX_','',rm)
orphans<-unname(sapply(orphans,function(x) ifelse(!grepl('SA_',x),paste0('zcode_',x),x)))

############################
############################ Bnet
############################

# Make bl/wl
blname<-paste0(data_out,'_bl.csv')
wlname<-paste0(data_out,'_wl.csv')
make_bl_wl_ppmi(discdata,blname,wlname,F,orphans) # rm has info about "orphaned" nodes (need to be connected to visitmiss, not to AUX)
bl<-read.csv(blname)
wl<-read.csv(wlname)

# Final bayesian network
finalBN = tabu(discdata, maxp=5, blacklist=bl,whitelist=wl,  score=scr)
saveRDS(finalBN,paste0(data_out,'_finalBN.rds'))

# Bootstrapped network
cores = detectCores()
cl =  makeCluster(cores)
boot.stren = boot.strength(discdata, algorithm="tabu", R=1000, algorithm.args = list(maxp=5, blacklist=bl, whitelist=wl, score=scr), cluster=cl)
stopCluster(cl)
saveRDS(boot.stren,paste0(data_out,'_bootBN.rds'))

# save fitted network
real = discdata
finalBN<-readRDS(paste0(data_out,'_finalBN.rds'))
fitted = bn.fit(finalBN, real, method=mth)
saveRDS(fitted,paste0(data_out,'_finalBN_fitted.rds'))

############################
############################ VP vs RP
############################

# Virtual Patient Generation
virtual<-simulate_VPs(real,finalBN,fitted,iterative=F,scr,mth,wl,bl)

############################
############################ save out all data
############################

# save out real and virtual patients
real$SUBJID<-pt
saveRDS(virtual,paste0(data_out,'_VirtualPPts.rds'))
write.csv(virtual,paste0(data_out,'_VirtualPPts.csv'),row.names=FALSE)
saveRDS(real,paste0(data_out,'_RealPPts.rds'))
real$SUBJID<-NULL
write.csv(real,paste0(data_out,'_RealPPts.csv'),row.names=FALSE)

# save out VP misslist (for HIVAE decoding, tells HIVAE which zcodes the BN considers missing)
save_VPmisslist(virtual,'data/HI-VAE/')

############################
############################ plot graphs in cytoscape (careful about dashed line maps!)
############################
source('network_plot_paper.R')
