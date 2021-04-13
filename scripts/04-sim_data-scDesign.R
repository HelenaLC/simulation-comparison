suppressPackageStartupMessages({
    library(scDesign)
    library(SingleCellExperiment)
})

fun <- function(x) {
    y <- counts(x)
    if (!is.matrix(y))
        y <- as.matrix(y)
    
    foo <- capture.output(
        z <- design_data(
            realcount = y,
            S = sum(y),
            ncell = ncol(y),
            ngroup = 1,
            ncores = 1))
    
    SingleCellExperiment(
        assays = list(counts = z))
}


