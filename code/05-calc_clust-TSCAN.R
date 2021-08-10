suppressPackageStartupMessages({
    library(scater)
    library(TSCAN)
})

fun <- \(x) 
{
    y <- normalizeCounts(x, log = TRUE)    
    y <- y[rowVars(y) > 0, , drop = FALSE]
    k <- length(unique(x$cluster))
    exprmclust(y, 
        clusternum = k,
        modelNames = "VVV",
        reduce = TRUE)$clusterid
}
