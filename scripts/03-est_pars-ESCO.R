suppressPackageStartupMessages({
  library(ESCO)
  library(SingleCellExperiment)
})

fun <- function(x) {
    y <- counts(x)
    if (!is.matrix(y))
        y <- as.matrix(y)
    dir <- tempdir()
    if (!is.null(x$batch)) {
        type <- "batch"
    } else if (!is.null(x$cluster)) {
        type <- "cluster"
    } else type <- "single"
    group <- type != "single"
    cellinfo <- x[[type]]
    suppressMessages(z <- escoEstimate(y, dir, group, cellinfo))
    list(params = z, type = type, groups = unique(x[[type]]))
}