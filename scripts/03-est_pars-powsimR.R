suppressPackageStartupMessages({
  library(powsimR)
  library(SingleCellExperiment)
})

fun <- function(x) {
  y <- counts(x)
  if (!is.matrix(y))
    y <- as.matrix(y)
  estimateParam(
    countData = y, 
    RNAseq = "singlecell",
    Protocol = "UMI",
    Distribution = "NB",
    Normalisation = "scran",
    NCores = 1,
    verbose = FALSE)
}