suppressPackageStartupMessages({
    library(RANN)
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
    # build KNN-graph on PCA
    # (where k = 5% of cells)
    pca <- reducedDim(sce, "PCA")
    k <- round(0.05*ncol(sce))
    knn <- nn2(pca, k = k+1)
    idx <- knn$nn.idx[, seq(2, k+1)]
    # count how often each cell is a KNN
    vapply(seq(ncol(sce)), \(i) sum(idx == i), numeric(1))
}

groups <- NULL
n_genes <- NULL
n_cells <- NULL