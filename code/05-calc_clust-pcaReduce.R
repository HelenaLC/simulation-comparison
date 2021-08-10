suppressPackageStartupMessages({
    library(clue)
    library(pcaReduce)
    library(scater)
})

fun <- \(x) 
{
    k <- length(unique(x$cluster))
    y <- normalizeCounts(x, log = TRUE)
    z <- PCAreduce(t(y),
        nbt = 100,
        q = q <- 30,
        method = "S")
    l <- lapply(z, function(.) {
        colnames(.) <- paste0("k", seq(q+1, 2))
        as.cl_partition(.[, paste0("k", k)])
    })
    e <- as.cl_ensemble(l)
    res <- cl_consensus(e,
        method = "SE",
        control = list(nruns = 50))
    c(cl_class_ids(res))
}