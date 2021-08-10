suppressPackageStartupMessages({
    library(BiocParallel)
    library(scDD)
    library(SingleCellExperiment)
})

fun <- function(x) {
    sink(tempfile())
    y <- do.call(simulateSet, x)
    sink()
    if (x$condition != "foo") {
        cd <- DataFrame(x$SCdat[[x$condition]])
        names(cd) <- x$condition
    } else {
        cd <- NULL
    }
    colData(y) <- cd
    rowData(y) <- NULL
    return(y)
}
