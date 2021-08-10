suppressPackageStartupMessages({
    library(SingleCellExperiment)
})

ppFUN <- function(sce) {
    sce
}

qcFUN <- function(sce) {
    colMeans(assay(sce) != 0)
}

groups <- NULL
n_genes <- NULL
n_cells <- NULL