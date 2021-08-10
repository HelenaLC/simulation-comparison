suppressPackageStartupMessages({
    library(batchelor)
    library(scater)
})

fun <- \(x)
{
    x <- logNormCounts(x)
    y <- calculatePCA(x, ncomponents = 20)
    
    k <- min(table(x$batch)/2)
    z <- fastMNN(x, 
        batch = x$batch, 
        k = k, d = 20)
    
    list(
        dimred_in = y,
        dimred_out = reducedDim(z))
}