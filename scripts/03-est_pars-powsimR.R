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
    GeneFilter = 0.1,
    SampleFilter = 3,
    verbose = FALSE)
}
