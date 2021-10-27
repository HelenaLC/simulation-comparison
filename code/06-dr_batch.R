suppressPackageStartupMessages({
    library(scater)
    library(scran)
    library(SingleCellExperiment)
})

# args <- list(
#     sce = "data/04-sim/Oetjen18,foo,SPARSim.rds",
#     res = "outs/batch_sim-Oetjen18,foo,SPARSim,mnnCorrect.rds")

x <- readRDS(args[[1]])
y <- readRDS(args[[2]])

df <- if (!is.null(x) && !is.null(y)) {
    if (!is.null(y$dimred_in) && 
        !is.null(y$dimred_out)) {
        # use integrated dimension reduction
        reducedDim(x, "PCA") <- y$dimred_out
    } else if (
        !is.null(y$assay_in) && 
        !is.null(y$assay_out)) {
        # run PCA on integrated data
        pca <- calculatePCA(y$assay_out)
        reducedDim(x, "PCA") <- pca
    }
    
    x <- runTSNE(x, dimred = "PCA")
    x <- runUMAP(x, dimred = "PCA")
    
    tsne <- reducedDim(x, "TSNE")
    umap <- reducedDim(x, "UMAP")
    colnames(tsne) <- paste0("TSNE", seq(2))
    colnames(umap) <- paste0("UMAP", seq(2))
    
    data.frame(wcs, tsne, umap, batch = x$batch)
}
saveRDS(df, args[[3]])
