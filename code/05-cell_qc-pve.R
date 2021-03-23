suppressPackageStartupMessages({
  library(BiocParallel)
  library(scater)
  library(SingleCellExperiment)
  library(variancePartition)
})

x <- readRDS(args$sce)

if (is.null(x$cluster) && is.null(x$batch)) {
  qc <- NA
} else {
  x <- logNormCounts(x)
  y <- as.matrix(logcounts(x))
  i <- ifelse(is.null(x$cluster), "batch", "cluster")
  f <- as.formula(sprintf("~(1|%s)", i))
  cd <- data.frame(colData(x)[i])
  pve <- fitExtractVarPartModel(y, f, cd, BPPARAM = SerialParam())
  qc <- data.frame(group = "global", id = "foo", cell_pve = pve[, i])  
}
