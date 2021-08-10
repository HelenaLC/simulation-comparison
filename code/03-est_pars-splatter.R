suppressPackageStartupMessages({
    library(splatter)
    library(SingleCellExperiment)
})

fun <- \(x) 
{
    if (!is.matrix(y <- counts(x)))
        counts(x) <- as.matrix(y)
    g <- if (!is.null(x$batch)) {
        "batch"
    } else if (!is.null(x$cluster)) {
        "cluster"
    }
    if (is.null(g)) {
        p <- splatEstimate(x)
    } else {
        i <- split(seq(ncol(x)), x[[g]], drop = TRUE)
        x <- lapply(i, function(.) x[, .])
        p <- lapply(x, splatEstimate)
    }
    list(pars = p, type = g)
}