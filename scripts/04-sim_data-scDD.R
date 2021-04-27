suppressPackageStartupMessages({
    library(BiocParallel)
    library(dplyr)
    library(scater)
    library(scDD)
})

fun <- function(x) {
    type <- names(colData(x))
    print(type)
    x <- logNormCounts(x, log = FALSE)
    
    if(!("batch" %in% names(colData(x)) || "cluster" %in% names(colData(x)))){
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
        #type g
        est <- scDD(x, condition=type, categorize = TRUE, testZeroes=TRUE)#default oder testZeroes=FALSE? When setting to FALSE note that some entries will be NA in $DDcategory!
        res <- results(est) %>% 
            filter(!is.na(DDcategory)) %>% 
            select("DDcategory") %>% 
            table() %>% 
            as.list()# DB, DE, DM, DP, DZ/NC ,NS(not significant)
        nDE = max(res$DE, 0, na.rm = TRUE)
        nDP = max(res$DP, 0, na.rm = TRUE)
        nDM = max(res$DM, 0, na.rm = TRUE)
        nDB = max(res$DB, 0, na.rm = TRUE)
        
#       Clusters.C1': the number of clusters identified in condition 1 alone
#      'Clusters.C2': the number of clusters identified in condition 2 alone
        # EP: equivalent proportion for MULTIMODAL genes
        nEP <- results(est) %>% 
            filter(DDcategory =="NS") %>% 
            select(c(Clusters.c1, Clusters.c2)) %>% 
            filter(Clusters.c1 >1 & Clusters.c2 > 1) %>% 
            nrow()
        
        print(res)
        sink(tempfile())
        y <- simulateSet(x,
                         numSamples = ceiling(ncol(x)/2),
                         nDE = nDE,
                         nDP = nDP,
                         nDM = nDM,
                         nDB = nDB,
                         nEE = nrow(x) - (nDE+nDP+nDM+nDB+nEP),
                         nEP = nEP,
                         plots = FALSE,
                         condition = type,
                         param = SerialParam())
        sink()
        colData(y) <- colData(x)
    }
    
    rowData(y) <- NULL
    assayNames(y) <- "counts" # scDD gives back normcounts, which we then call counts to perform logNormcounts etc in the future for e.g. dimension reduction
    dimnames(y) <- list(NULL, NULL)
    
    return(y)
}
