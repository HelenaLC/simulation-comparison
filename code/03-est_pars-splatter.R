suppressPackageStartupMessages({
    library(splatter)
    library(SingleCellExperiment)
})

fun <- function(x) {
    y <- counts(x)
    if (!is.matrix(y))
        y <- as.matrix(y)
    splatEstimate(y)
}