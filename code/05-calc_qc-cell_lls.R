suppressPackageStartupMessages({
    library(SingleCellExperiment)
})

ppFUN <- function(sce) {
    sce
}

qcFUN <- function(sce) {
    if ("counts" %in% assayNames(sce))
        log(colSums(counts(sce) + 1))
}

groups <- NULL
n_genes <- NULL
n_cells <- NULL