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
    return(sce)
}

qcFUN <- function(sce) {
    rowVars(assay(sce, "exprs"))
}

groups <- NULL
n_genes <- NULL
n_cells <- NULL