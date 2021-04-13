suppressPackageStartupMessages({
    library(BASiCS)
    library(SingleCellExperiment)
})

fun <- function(x) {
    suppressMessages({
        y <- BASiCS_Sim(
            Mu = x$mu,
            Mu_spikes = NULL,
            Delta = x$delta,
            Phi = NULL,
            S = x$s,
            Theta = x$theta,
            BatchInfo = x$bi)
    })
    y$batch <- x$batch
    y$BatchInfo <- NULL
    return(y)
}