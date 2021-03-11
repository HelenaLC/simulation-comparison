suppressPackageStartupMessages({
  library(SymSim)
  library(SingleCellExperiment)
})

# args <- list(sce="data/02-sub/CellBench,H1975.rds",fun="code/03-est_pars-BASiCS.R",est="data/03-est/CellBench,H1975,BASiCS.rds"  )


fun <- function(x){
  optimal_param <- BestMatchParams(tech='UMI', counts = as.matrix(counts(x)), plotfilename = "SymSim_param_est", n_optimal=1) # UMI? or nonUMI?
  optimal_param$ncells_total = ncol(x)
  optimal_param$ngenes = nrow(x)
  
  if (is.null(x$batch)) {
    optimal_param$nbatch = 1 
  } else {
  optimal_param$nbatch = length(unique(x$batch))
  }
  
  return(list(batch=x$batch, optimal_param=optimal_param))
  }