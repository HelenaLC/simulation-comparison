suppressPackageStartupMessages({
  library(powsimR)
  library(SingleCellExperiment)
})

fun <- function(x) {
  y <- simulateDE(
    SetupRes = x,
    Normalisation = "scran",
    DEmethod = "DESeq2",
    Counts = TRUE,
    NCores = NULL,
    verbose = TRUE)
  # remove group 2 cells
  z <- y$Counts[[1]][[1]][, -c(1, 2)]
  SingleCellExperiment(assays = list(counts = z))
}

