missingD <- function(dat) {
  # return column i's where more than 50% of data is present
  out <- apply(is.na(dat),2, mean)
  unlist(which(out<0.5))
}

######### return column i's where variance is not 0
includeVar <- function(dat) {
  out <- lapply(dat, function(x) length(unique(x[!is.na(x)])))
  want <- which(out > 1)
  unlist(want)
}

######### return column i's where missing data <50%
rmMiss <- function(dat) {
  out <- lapply(dat, function(x) mean(is.na(x)))
  want <- which(out < 0.5)
  unlist(want)
}

######### rescale between 0 and 1
rescale<-function(x){
  (x-min(x))/(max(x) - min(x))
}
