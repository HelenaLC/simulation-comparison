suppressPackageStartupMessages({
    library(BiocParallel)
    library(scDD)
    library(SingleCellExperiment)
})

fun <- function(x) {
    if (!is.matrix(y <- counts(x)))
        counts(x) <- as.matrix(y)
    n_genes <- nrow(x)
    n_cells <- ceiling(ncol(x)/2)
    BPPARAM <- SerialParam()
    if (is.null(x$batch) && is.null(x$cluster)) {
        # type n
        x$foo <- sample(2, ncol(x), TRUE)
        x <- preprocess(x, 
            condition = "foo", 
            scran_norm = TRUE)
        y <- list(
            nDE = 0, nDP = 0, nDM = 0, 
            nDB = 0, nEE = n_genes, nEP = 0, 
            condition = "foo")
    } else {
        # type g
        type <- ifelse(!is.null(x$batch), "batch", "cluster")
        x <- preprocess(x, 
            condition = type, 
            scran_norm = TRUE)
        est <- scDD(x, 
            condition = type, 
            testZeroes = FALSE, 
            param = SerialParam()) 
        res <- results(est)
        res <- res[!is.na(res$DDcategory), ]
        # get number of DD genes
        nDD <- as.list(table(res$DDcategory))
        nDE <- max(nDD$DE, 0); nDP <- max(nDD$DP, 0)
        nDM <- max(nDD$DM, 0); nDB <- max(nDD$DB, 0)
        # get number of EE/P genes
        NS <- res[res$DDcategory == "NS", ]
        nEP <- with(NS, sum(Clusters.c1 > 1 & Clusters.c2 > 1))
        nEE <- n_genes - (nDE + nDP + nDM + nDB + nEP)
        y <- list(
            nDE = nDE, nDP = nDP, nDM = nDM, 
            nDB = nDB, nEE = nEE, nEP = nEP, 
            condition = type)
    }
    c(y, list(
        SCdat = x,
        numSamples = n_cells,
        plots = FALSE,
        param = BPPARAM))
}
