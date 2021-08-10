suppressPackageStartupMessages({
    library(batchelor)
    library(scater)
})

fun <- \(x)
{
    x <- logNormCounts(x)
    k <- min(table(x$batch)/2)
    y <- mnnCorrect(x, batch = x$batch, k = k)
    
    list(
        assay_in = logcounts(x),
        assay_out = assay(y))
}