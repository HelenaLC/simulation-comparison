suppressPackageStartupMessages({
  library(reticulate)
  library(SingleCellExperiment)
})
# need to set path in .Rprofile
# Sys.setenv(RETICULATE_PYTHON = "/Users/sarahmorillo/anaconda3/envs/sim_comp/bin/python")
use_condaenv(condaenv = 'sim_comp', required = TRUE)


fun <- function(x){
  source_python("code/03-est_pars-SERGIO.py")
  sim <- simulate()  
  sim <- SingleCellExperiment(list(counts=as.data.frame(sim)))
  print(sim)
  return(sim)
}


