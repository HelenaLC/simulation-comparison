suppressPackageStartupMessages({
  library(dyngen)
  library(SingleCellExperiment)
})

fun <- function(x) {
  sink(tempfile())
  y <- generate_dataset(x, 
    format = "sce", 
    make_plots = FALSE)
  sink()
  
  sim <- SingleCellExperiment(list(counts=sim$dataset$counts))
  
  return(sim)
}