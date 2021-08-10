suppressPackageStartupMessages({
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
    es <- assay(sce, "exprs")
    sd <- sqrt(rowVars(es))
    mu <- rowMeans(es)
    cv <- sd / mu
    cv[!is.na(cv)]
}

groups <- NULL
n_genes <- NULL
n_cells <- NULL