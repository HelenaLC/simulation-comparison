suppressPackageStartupMessages({
    library(scDesign)
    library(SingleCellExperiment)
})

fun <- function(x) {
    y <- counts(x)
    if (!is.matrix(y))
        y <- as.matrix(y)
    
    if(ncol(colData(x)) == 0){
        #type n
        foo <- capture.output(
            z <- design_data(
                realcount = y,
                S = sum(y),
                ncell = ncol(y),
                ngroup = 1,
                ncores = 1))
        
        SingleCellExperiment(
            assays = list(counts = z))
    }else{
        # type k (cell states)
        S <- sapply(unique(x$cluster), function(cl){sum(counts(x)[, which(x$cluster == cl)] )})
        ncell <- sapply(unique(x$cluster), function(cl){length(which(x$cluster == cl))})
        f <- .find_markers(x, "cluster")
        foo <- capture.output(
            z <- design_data(
                realcount = y,
                S = S,
                ncell = ncell,
                pUp = f$pUp, pDown = f$pDown,
                ngroup = length(unique(x$cluster)),
                ncores = 1))
        
        sim <- do.call(cbind, z$count)
        SingleCellExperiment(
            assays = list(counts = sim), colData = colData(x))    
    }
    
}