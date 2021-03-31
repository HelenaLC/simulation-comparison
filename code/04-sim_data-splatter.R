suppressPackageStartupMessages({
    library(splatter)
    library(SingleCellExperiment)
})

fun <- function(x) {
    y <- splatSimulate(x, verbose = FALSE)
    metadata(y) <- list()
    rowData(y) <- colData(y) <- NULL
    assays(y) <- assays(y)["counts"]
    return(y)
}