suppressPackageStartupMessages({
  library(scater)
  library(variancePartition)
})

ppFUN <- function(sce) {
  i <- rowSums(counts(sce)) != 0
  logNormCounts(sce[i, ])
}

qcFUN <- function(sce) {
  if (is.null(sce$cluster) 
      && is.null(sce$batch)) 
      return(NULL)
  y <- logcounts(sce)
  i <- ifelse(is.null(sce$cluster), "batch", "cluster")
  f <- as.formula(sprintf("~(1|%s)", i))
  cd <- data.frame(colData(sce)[i])
  fitExtractVarPartModel(y, f, cd, BPPARAM = SerialParam())[, i]
}

groups <- "global"
n_genes <- NULL
n_cells <- NULL