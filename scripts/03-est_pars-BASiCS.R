suppressPackageStartupMessages({
    library(BASiCS)
    library(SingleCellExperiment)
})

fun <- function(x) {
    suppressMessages({
        foo <- capture.output({
            x$BatchInfo <- as.numeric(x$batch)
            mcmc <- BASiCS_MCMC(Data = x,
                N = 1e4, Thin = 10, Burn = 5e3,
                Regression = TRUE, WithSpikes = FALSE)
        })
    })
    mcmc <- Summary(mcmc)
    names(ps) <- ps <- c("mu", "delta", "s", "theta")
    ps <- lapply(ps, function(p) displaySummaryBASiCS(mcmc, p)[, 1])
    c(ps, list(bi = x$BatchInfo, batch = x$batch))
}