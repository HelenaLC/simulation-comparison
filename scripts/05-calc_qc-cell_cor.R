suppressPackageStartupMessages({
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
    cor <- cor(
        log(cpm(sce)+1),                 
        method = "spearman",
        use = "pairwise.complete.obs")
    cor[upper.tri(cor)]
}

groups <- NULL
n_genes <- NULL
n_cells <- 200