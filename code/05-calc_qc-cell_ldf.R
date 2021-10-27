suppressPackageStartupMessages({
    library(BiocNeighbors)
    library(CellMixS)
    library(dplyr)
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
    i <- c("batch", "cluster")
    i <- intersect(i, names(colData(sce)))
    k <- if (length(i) != 0) {
        # half of smallest group
        ids <- factor(sce[[i]])
        n <- tabulate(ids)
        min(n[n != 0])/2
    } else {
        # 5% of total cells
        0.05*ncol(sce)
    }
    # KNN on PCA
    pca <- reducedDim(sce, "PCA")
    knn <- findKNN(pca, k)
    # fix naming for indexing
    cs <- colnames(sce)
    rownames(knn$index) <- cs
    rownames(knn$distance) <- cs
    knn$cell_name <- knn$index
    # compute local density factors
    c(CellMixS:::.ldfKnn(pca, knn, k)$LDF)
}

groups <- NULL
n_genes <- NULL
n_cells <- NULL