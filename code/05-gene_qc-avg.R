suppressPackageStartupMessages({
    library(scater)
})

ppFUN <- function(sce) {
    cpm <- calculateCPM(sce)
    assay(sce, "cpm") <- cpm
    return(sce)
}

qcFUN <- function(sce) {
    rowMeans(log(cpm(sce) + 1))
}

groups <- NULL
n_genes <- NULL
n_cells <- NULL