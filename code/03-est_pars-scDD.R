suppressPackageStartupMessages({
    library(BiocParallel)
    library(scDD)
    library(SingleCellExperiment)
})

fun <- function(x) {
    if (!is.matrix(y <- counts(x)))
        counts(x) <- as.matrix(y)
    # randomly split cells into 2 groups
    x$foo <- sample(2, ncol(x), TRUE)
    x <- preprocess(x, 
        condition = "foo", 
        scran_norm = TRUE)
    list(
        SCdat = x,
        condition = "foo",
        plots = FALSE,
        param = SerialParam(),
        nDE = 0, nDP = 0, nDM = 0, 
        nDB = 0, nEE = nrow(x), nEP = 0,
        numSamples = ceiling(ncol(x)/2))
}
