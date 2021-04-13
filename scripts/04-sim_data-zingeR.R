suppressPackageStartupMessages({
    library(gamlss)
    library(gamlss.tr)
    library(mgcv)
    library(SingleCellExperiment)
    library(zingeR)
})

fun <- function(x) {
    y <- do.call(NBsimSingleCell, x)
    SingleCellExperiment(list(counts = y$counts))
}
