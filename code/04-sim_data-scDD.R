suppressPackageStartupMessages({
    library(BiocParallel)
    library(scDD)
    library(SingleCellExperiment)
})

fun <- function(x) {
    sink(tempfile())
    y <- do.call(simulateSet, x)
    sink()
    colData(y) <- rowData(y) <- NULL
    return(y)
}
