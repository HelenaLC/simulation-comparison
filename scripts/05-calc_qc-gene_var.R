suppressPackageStartupMessages({
  library(matrixStats)
  library(scater)
})

ppFUN <- function(sce) {
  cpm <- calculateCPM(sce)
  if (!is.matrix(cpm))
      cpm <- as.matrix(cpm)
  assay(sce, "cpm") <- cpm
  return(sce)
}

qcFUN <- function(sce) {
  rowVars(log(cpm(sce) + 1))
}

groups <- NULL
n_genes <- NULL
n_cells <- NULL