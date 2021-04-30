suppressPackageStartupMessages({
    library(BiocParallel)
    library(dplyr)
    library(scater)
    library(scDD)
})

fun <- function(x) {
    n_genes <- nrow(x)
    n_cells <- ceiling(ncol(x)/2)
    x <- logNormCounts(x, log = FALSE)
    BPPARAM <- SerialParam()
    if (is.null(x$batch) && is.null(x$cluster)) {
        # type n
        x$foo <- sample(2, ncol(x), TRUE)
        y <- list(
            nDE = 0, nDP = 0, nDM = 0, 
            nDB = 0, nEE = n_genes, nEP = 0, 
            condition = "foo")
    } else {
        # type g
        type <- ifelse(!is.null(x$batch), "batch", "cluster")
        # when testZeroes = FALSE, 'DDcategory' can be NA
        est <- scDD(x, 
            condition = type, 
            categorize = TRUE, 
            testZeroes = TRUE, 
            param = SerialParam()) 
        res <- results(est)
        # get estimates for number of ... genes
        # DB, DE, DM, DP, DZ, NS (not significant)
        nDD <- res %>% 
            filter(!is.na(DDcategory)) %>% 
            pull("DDcategory") %>% 
            table() %>% 
            as.list()
        nDE <- max(res$DE, 0, na.rm = TRUE)
        nDP <- max(res$DP, 0, na.rm = TRUE)
        nDM <- max(res$DM, 0, na.rm = TRUE)
        nDB <- max(res$DB, 0, na.rm = TRUE)
        nEP <- res %>% 
            filter(DDcategory == "NS") %>% 
            filter(across(c(Clusters.c1, Clusters.c2), ~.x > 1)) %>% 
            nrow()
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