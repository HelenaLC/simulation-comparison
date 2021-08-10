suppressPackageStartupMessages({
    library(Rtsne)
    library(scater)
})

fun <- \(x) 
{
    k <- length(unique(x$cluster))
    y <- normalizeCounts(x, log = TRUE)
    if (!is.matrix(y)) y <- as.matrix(y)
    tsne <- Rtsne(t(y), 
        pca = TRUE, initial_dims = 50, dims = 3,
        perplexity = 30, check_duplicates = FALSE)
    kmeans(tsne$Y, centers = k, nstart = 25)$cluster
}