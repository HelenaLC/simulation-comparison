suppressPackageStartupMessages({
    library(scater)
    library(SingleCellExperiment)
})

fun <- \(x) 
{
    y <- normalizeCounts(x, log = TRUE)
    pca <- prcomp(t(y), center = TRUE, scale. = FALSE)
    pca <- pca$x[, seq(20), drop = FALSE]
    hc <- hclust(dist(pca), method = "ward.D2")
    cutree(hc, k = length(unique(x$cluster)))
}