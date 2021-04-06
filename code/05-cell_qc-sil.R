suppressPackageStartupMessages({
    library(cluster)
    library(scater)
    library(SingleCellExperiment)
})

ppFUN <- function(sce) {
    sce <- logNormCounts(sce)
    sce <- runPCA(sce)
}

qcFUN <- function(sce) {
    if (is.null(sce$cluster) 
        && is.null(sce$batch))
        return(NULL)
    i <- ifelse(is.null(sce$cluster), "batch", "cluster")
    ids <- as.integer(factor(sce[[i]]))
    mtx <- dist(reducedDim(sce, "PCA"))
    swd <- silhouette(ids, mtx)
    return(swd[, "sil_width"])
}

groups <- "global"
n_genes <- NULL
n_cells <- NULL