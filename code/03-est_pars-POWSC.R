suppressPackageStartupMessages({
    library(POWSC)
    library(SingleCellExperiment)
})

fun <- function(x) {
    if (!is.matrix(y <- counts(x)))
        counts(x) <- as.matrix(y)
    if (is.null(x$cluster)) {
        y <- Est2Phase(x)
    } else {
        i <- split(seq(ncol(x)), x$cluster, drop = TRUE)
        y <- lapply(i, function(.) Est2Phase(x[, .]))
    }
}
