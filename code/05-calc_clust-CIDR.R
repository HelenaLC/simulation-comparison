suppressPackageStartupMessages({
    library(cidr)
    library(SingleCellExperiment)
})

fun <- \(x) 
{
    y <- counts(x)
    if (!is.matrix(y))
        y <- as.matrix(y)
    k <- length(unique(x$cluster))
    
    z <- scDataConstructor(y, tagType = "raw")
    z <- determineDropoutCandidates(z)
    z <- wThreshold(z)
    z <- scDissim(z, threads = 1)
    z <- scPCA(z, plotPC = FALSE)
    z <- nPC(z)
    
    scCluster(
        object = z, 
        nCluster = k, 
        nPC = z@nPC, 
        cMethod = "ward.D2")@clusters
}