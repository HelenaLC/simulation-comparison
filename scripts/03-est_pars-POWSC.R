suppressPackageStartupMessages({
    library(POWSC)
    library(SingleCellExperiment)
})

fun <- function(x) {
    y <- counts(x)
    if (!is.matrix(y)) {
        y <- as.matrix(y)
        counts(x) <- y
    }
    
    if (is.null(x$cluster)) {
        y <- Est2Phase(x)
    } else {
        i <- split(seq_len(ncol(x)), x$cluster)
        y <- lapply(i, function(.) Est2Phase(x[, .]))
    }
}
