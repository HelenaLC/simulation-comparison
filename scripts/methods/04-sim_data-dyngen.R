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
  return(y$dataset)
}