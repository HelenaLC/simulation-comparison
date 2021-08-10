suppressPackageStartupMessages({
    library(scater)
})

fun <- \(x) 
{
    y <- normalizeCounts(x, log = TRUE)
    k <- length(unique(x$cluster))
    pca <- prcomp(t(y), center = TRUE, scale. = FALSE)
    pca <- pca$x[, seq(30), drop = FALSE]
    kmeans(pca, centers = k, nstart = 25)$cluster
}