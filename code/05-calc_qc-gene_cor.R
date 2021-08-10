suppressPackageStartupMessages({
  library(matrixStats)
  library(scater)
})

ppFUN <- function(sce) {
    if (!is.matrix(y <- assay(sce))) 
        assay(sce) <- as.matrix(y)
    y <- if ("normcounts" %in% assayNames(sce)) {
        normcounts(sce)
    } else calculateCPM(sce)
    assay(sce, "exprs") <- log(y+1)
    sce[rowVars(y) > 0, ]
}

qcFUN <- function(sce) {
    cor <- cor(
        t(assay(sce, "exprs")),
        method = "spearman",
        use = "pairwise.complete.obs")
    cor[upper.tri(cor)]
}

groups <- NULL
n_genes <- 400
n_cells <- NULL