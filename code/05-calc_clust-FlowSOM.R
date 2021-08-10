suppressPackageStartupMessages({
    library(ConsensusClusterPlus)
    library(flowCore)
    library(FlowSOM)
    library(scater)
    library(SingleCellExperiment)
})

fun <- \(x) 
{
    k <- length(unique(x$cluster))
    y <- normalizeCounts(x, log = TRUE)
    pca <- prcomp(t(y), center = TRUE, scale. = FALSE)
    pca <- pca$x[, seq(20), drop = FALSE]
    ff <- flowFrame(exprs = pca)
    som <- ReadInput(ff, 
        compensate = FALSE,
        transform = FALSE,
        scale = FALSE,
        silent = TRUE)
    som <- BuildSOM(som,
        silent = TRUE,
        xdim = 10, 
        ydim = 10)
    mc <- ConsensusClusterPlus(t(som$map$codes), k = k)
    mc[, som$map$mapping[, 1]]
}