suppressPackageStartupMessages({
    library(cluster)
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
    if (length(i) == 0) return(NULL)
    ids <- as.integer(factor(sce[[i]]))
    mtx <- dist(reducedDim(sce, "PCA"))
    res <- silhouette(ids, mtx)
    return(res[, "sil_width"])
}

groups <- "global"
n_genes <- NULL
n_cells <- NULL