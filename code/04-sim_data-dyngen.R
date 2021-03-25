suppressPackageStartupMessages({
  library(dyngen)
  library(SingleCellExperiment)
})

fun <- function(x) {
  sim <- generate_dataset(x, make_plots = FALSE)
  sim <- SingleCellExperiment(list(counts=sim$dataset$counts))
  
  return(sim)
}