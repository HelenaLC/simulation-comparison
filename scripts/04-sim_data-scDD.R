suppressPackageStartupMessages({
    library(BiocParallel)
    library(scater)
    library(scDD)
})

fun <- function(x) {
    type <- names(colData(x))
    print(type)
    x <- logNormCounts(x, log = FALSE)
    
    if(!("batch" %in% names(colData(x)) || "cluster" %in% names(colData(x)))){
        print("type n")
        # type n
        x$foo <- sample(2, ncol(x), TRUE)
        # x$foo <- rep(1, ncol(x)) this does not work, it NEEDS two groups... -> only of type g? 
        sink(tempfile())
        y <- simulateSet(x,
                         numSamples = ceiling(ncol(x)/2),
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
        colData(y) <- NULL
    }else{
        print("type g")
        #type g
        f <- .find_markers(x, type)
        sink(tempfile())
        y <- simulateSet(x,
                         numSamples = ceiling(ncol(x)/2),
                         nDE = f$pDE * nrow(x),
                         nDP = 0,
                         nDM = 0,
                         nDB = 0,
                         nEE = nrow(x) - f$pDE * nrow(x),
                         nEP = 0,
                         plots = FALSE,
                         condition = type,
                         param = SerialParam())
        sink()
        colData(y) <- colData(x)
    }
    
    # x <- logNormCounts(x, log = FALSE)
    # x$foo <- sample(2, ncol(x), TRUE)
    # 
    # sink(tempfile())
    # y <- simulateSet(x,
    #     numSamples = ceiling(ncol(x)/2),
    #     nDE = ,
    #     nDP = 0,
    #     nDM = 0,
    #     nDB = 0,
    #     nEE = nrow(x),
    #     nEP = 0,
    #     plots = FALSE,
    #     condition = "foo",
    #     param = SerialParam())
    # sink()

    # rowData(y) <- NULL
    # colData(y) <- NULL
    # assayNames(y) <- "counts"
    # dimnames(y) <- list(NULL, NULL)
    
    
    rowData(y) <- NULL
    assayNames(y) <- "counts" # scDD gives back normcounts, which we then call counts to perform logNormcounts etc in the future for e.g. dimension reduction
    dimnames(y) <- list(NULL, NULL)
    
    return(y)
}
