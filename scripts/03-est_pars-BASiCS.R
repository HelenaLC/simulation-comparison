suppressPackageStartupMessages({
    library(BASiCS)
    library(SingleCellExperiment)
})

fun <- function(x) {
    suppressMessages({
        foo <- capture.output({
            x$BatchInfo <- as.numeric(x$batch)
            mcmc <- BASiCS_MCMC(Data = x,
                N=1000, Thin=20, Burn=500, #NOTE: WE USE A SMALL NUMBER OF ITERATIONS FOR ILLUSTRATION PURPOSES ONLY. LARGER NUMBER OF ITERATIONS ARE USUALLY REQUIRED TO ACHIEVE CONVERGENCE. OUR RECOMMENDED SETTING IS N=20000, Thin=20 and Burn=10000
                Regression = TRUE, WithSpikes = FALSE)
        })
    })
    mcmc <- Summary(mcmc)
    names(ps) <- ps <- c("mu", "delta", "s", "theta")
    ps <- lapply(ps, function(p) displaySummaryBASiCS(mcmc, p)[, 1])
    c(ps, list(bi = x$BatchInfo, batch = x$batch))
}