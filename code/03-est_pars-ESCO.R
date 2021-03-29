suppressPackageStartupMessages({
  library(ESCO)
  library(SingleCellExperiment)
})

fun <- function(x){
  
  # if(!is.null(x$batch)){
  #   param <- escoEstimate(as.matrix(counts(x)), group=TRUE, cellinfo = x$batch)
  #   type = "group"
  # }
  # if(!is.null(x$cluster)){
  #   param <- escoEstimate(as.matrix(counts(x)), group=TRUE, cellinfo = x$cluster)
  #   type = "group"
  # 
  # }else{
    param <- escoEstimate(as.matrix(counts(x)))  
    type = "single" 
  # }
  
  return(list(param = param, type = type))
}