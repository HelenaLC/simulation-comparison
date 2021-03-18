suppressPackageStartupMessages({
    library(POWSC)
    library(SingleCellExperiment)
})

fun <- function(x) {
    if (!is.list(x[[1]])) {
        y <- Simulate2SCE(
            n = ncol(x$exprs),
            perDE = 0,
            estParas1 = x,
            estParas2 = x)
        
        y <- y$sce
        rowData(y) <- NULL
        colData(y) <- NULL
    } else {
        ns <- vapply(x, function(.) 
            ncol(.$exprs), numeric(1))
        
        y <- SimulateMultiSCEs(
            n = sum(ns),
            estParas_set = x,
            multiProb = ns)
    
        y <- lapply(y, function(.) .$sce)
        y <- do.call(cbind, y)
        
        y$cluster <- y$cellTypes
        y$cellTypes <- NULL
        rowData(y) <- NULL
    }
    return(y)
}