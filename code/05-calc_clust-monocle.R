suppressPackageStartupMessages({
    library(monocle)
    library(scran)
})

fun <- \(x) 
{
    if (!is.matrix(y <- counts(x)))
        counts(x) <- as.matrix(y)
    if (is.null(rownames(x)))
        rownames(x) <- paste0("gene", seq(nrow(x)))
    k <- length(unique(x$cluster))
    rowData(x)$gene_short_name <- rownames(x)
    y <- convertTo(x, type = "monocle")
    y <- estimateSizeFactors(y)
    y <- tryCatch(
        estimateDispersions(y),
        error = function(e) y)
    y <- reduceDimension(y, 
        max_components = 3,
        num_dim = 50,
        reduction_method = "tSNE",
        verbose = TRUE)
    monocle::clusterCells(y, 
        num_clusters = k+1,
        method = "densityPeak")$Cluster
}