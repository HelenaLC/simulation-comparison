suppressPackageStartupMessages({
    library(SingleCellExperiment)
    library(zinbwave)
})

fun <- function(x) {
    y <- zinbSim(x$obj)
    SingleCellExperiment(
        list(counts = y$counts), 
        colData = x$cd)
}
