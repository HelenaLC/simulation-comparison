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
    cpm <- log(cpm(sce) + 1)
    sd <- sqrt(rowVars(cpm))
    mu <- rowMeans(cpm)
    cv <- sd / mu
    cv[!is.na(cv)]
}

groups <- NULL
n_genes <- NULL
n_cells <- NULL