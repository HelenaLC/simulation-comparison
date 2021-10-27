suppressPackageStartupMessages({
    library(scater)
    library(scran)
    library(SingleCellExperiment)
})

set.seed(7043)
x <- readRDS(args[[1]])

# skip if simulation failed (return NULL)
df <- if (!is.null(x)) {
    if ("normcounts" %in% assayNames(x)) {
        logcounts(x) <- log(normcounts(x)+1)
    } else x <- logNormCounts(x)
    
    stats <- modelGeneVar(x)
    hvgs <- getTopHVGs(stats, n = 500)
    
    x <- runPCA(x, subset_row = hvgs)
    x <- runTSNE(x, dimred = "PCA")
    x <- runUMAP(x, dimred = "PCA")
    
    tsne <- reducedDim(x, "TSNE")
    umap <- reducedDim(x, "UMAP")
    colnames(tsne) <- paste0("TSNE", seq(2))
    colnames(umap) <- paste0("UMAP", seq(2))
    
    x$lls <- if ("counts" %in% assayNames(x))
        x$lls <- log(colSums(counts(x))+1) else NA
    
    i <- c("cluster", "batch", "lls")
    i <- intersect(names(colData(x)), i)
    cd <- colData(x)[i]
    
    data.frame(wcs, cd, tsne, umap)
}

saveRDS(df, args[[2]])
