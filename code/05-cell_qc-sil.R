suppressPackageStartupMessages({
    library(cluster)
    library(dplyr)
    library(purrr)
    library(scater)
    library(SingleCellExperiment)
})

# setwd("~/Desktop/LabRotation_Robinson/simulation-comparison")
# args <- list(
#     sce = "data/04-sim/panc8,indrop_alpha,splatter.rds",
#     con = "config/metrics.json")
# wcs <- list(metric = "cell_sil")

x <- readRDS(args$sce)

if (is.null(x$cluster)) {
    qc <- NA
} else {
    x <- logNormCounts(x)
    x <- runPCA(x)
    FUN <- function(x) { 
        kids <- as.integer(factor(x$cluster))
        dmat <- dist(reducedDim(x, "PCA"))
        swd <- silhouette(kids, dmat)
        return(swd[, "sil_width"])
    }
    nm <- paste(wcs$type, wcs$metric, sep = "_")
    qc <- .calc_qc_for_splits(x=x, metric_name=nm, i=NULL, FUN=FUN) 
}
saveRDS(qc, args$res)
