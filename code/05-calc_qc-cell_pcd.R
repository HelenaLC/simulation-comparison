suppressPackageStartupMessages({
    library(scater)
    library(scran)
    library(SingleCellExperiment)
})

ppFUN <- function(sce) {
    if ("normcounts" %in% assayNames(sce)) {
        logcounts(sce) <- log(normcounts(sce)+1)
    } else sce <- logNormCounts(sce)
    stats <- modelGeneVar(sce)
    hvgs <- getTopHVGs(stats, n = 500)
    sce <- runPCA(sce, subset_row = hvgs)
}

qcFUN <- function(sce) {
    pca <- reducedDim(sce, "PCA")
    c(dist(pca, upper = TRUE))
}

groups <- NULL
n_genes <- NULL
n_cells <- 200