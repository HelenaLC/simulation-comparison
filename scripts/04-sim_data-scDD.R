suppressPackageStartupMessages({
    library(BiocParallel)
    library(scater)
    library(scDD)
})

fun <- function(x) {
    x <- logNormCounts(x, log = FALSE)
    x$foo <- sample(2, ncol(x), TRUE)

    sink(tempfile())
    y <- simulateSet(x,
        numSamples = ncol(x),
        nDE = 0,
        nDP = 0,
        nDM = 0,
        nDB = 0,
        nEE = nrow(x),
        nEP = 0,
        plots = FALSE,
        condition = "foo",
        param = SerialParam())
    sink()

    rowData(y) <- NULL
    colData(y) <- NULL
    assayNames(y) <- "counts"
    dimnames(y) <- list(NULL, NULL)
    
    return(y)
}
