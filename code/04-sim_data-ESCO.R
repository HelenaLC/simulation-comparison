suppressPackageStartupMessages({
  library(ESCO)
  library(SingleCellExperiment)
})

fun <- function(x){
  
  sim <- escoSimulate(params = x$param, type = c(x$type), verbose = TRUE)

  if(!("counts" %in% names(assays(sim)))){
    assays(sim)$counts <- assays(sim)$observedcounts
  }

  return(sim)
}
