suppressPackageStartupMessages({
    library(gamlss)
    library(gamlss.tr)
    library(mgcv)
    library(SingleCellExperiment)
    library(zingeR)
})

fun <- function(x) {
    y <- do.call(NBsimSingleCell, x$pars)
    cd <- switch(x$type,
        b = DataFrame(batch = y$group),
        k = DataFrame(cluster = y$group),
        n = make_zero_col_DFrame(ncol(y)))
    SingleCellExperiment(list(counts = y$counts), colData = cd)
}
