suppressPackageStartupMessages({
  library(matrixStats)
  library(scater)
})

ppFUN <- function(sce) {
  cpm <- calculateCPM(sce)
  if (!is.matrix(cpm))
    cpm <- as.matrix(cpm)
  assay(sce, "cpm") <- cpm
  sce[rowVars(cpm) > 0, ]
}

qcFUN <- function(sce) {
  cpm <- log(cpm(sce)+1)
  cor <- cor(t(cpm),
    method = "spearman",
    use = "pairwise.complete.obs")
  cor[upper.tri(cor)]
}

groups <- NULL
n_genes <- 400
n_cells <- NULL