# need to set path in .Rprofile
# Sys.setenv(RETICULATE_PYTHON = "/Users/sarahmorillo/anaconda3/envs/sim_comp/bin/python")

suppressPackageStartupMessages({
  library(reticulate)
  library(SingleCellExperiment)
})

use_condaenv(condaenv = "sim_comp", required = TRUE)

fun <- function(x){
    source_python("code/03-est_pars-SERGIO.py")
    y <- as.matrix(simulate())
    SingleCellExperiment(list(counts = y))
}