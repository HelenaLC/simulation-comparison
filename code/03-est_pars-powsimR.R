suppressPackageStartupMessages({
  library(powsimR)
  library(SingleCellExperiment)
})

fun <- function(x) {
  y <- counts(x) 
  if (!is.matrix(y))
    y <- as.matrix(y)
  
  args <- list(
    countData = y,
    RNAseq = "singlecell",
    Protocol = "UMI",
    Distribution = "NB",
    Normalisation = "scran",
    GeneFilter = 0,
    SampleFilter = Inf,
    NCores = 1,
    verbose = FALSE)

  if (is.null(x$batch) && is.null(x$cluster)) {
    # type n
    p <- do.call(estimateParam, args)
    list(
      pars = p,
      type = "n")
  } else {
    # type g
    type <- ifelse(!is.null(x$batch), "batch", "cluster")
    mgs <- .find_markers(x, group = type)
    ns <- table(group <- colData(x)[[type]])
    args$batchData <- data.frame(group, row.names = colnames(x))
    p <- do.call(estimateParam, args)
    list(
      pars = p, 
      type = type, 
      markers = mgs, 
      colData = colData(x),
      n1 = ns[[1]], 
      n2 = ns[[2]])
  }
}
