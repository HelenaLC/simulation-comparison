suppressPackageStartupMessages({
    library(scDesign)
    library(SingleCellExperiment)
})

fun <- function(x) {
    y <- counts(x)
    if (!is.matrix(y))
        y <- as.matrix(y)
    
    if (is.null(x$cluster)) {
        # type n
        foo <- capture.output(
            z <- design_data(
                realcount = y,
                S = sum(y),
                ncell = ncol(y),
                ngroup = 1,
                ncores = 1))
        
        SingleCellExperiment(
            assays = list(counts = z))
    } else {
        # type k
        i <- split(seq(ncol(x)), x$cluster, drop = TRUE)
        S <- vapply(i, function(.) sum(y[, .]), numeric(1))
        ncell <- vapply(i, length, numeric(1))
        mgs <- .find_markers(x, "cluster")
        foo <- capture.output(
            z <- design_data(
                realcount = y,
                S = S,
                ncell = ncell,
                pUp = mgs$pUp, 
                pDown = mgs$pDown, 
                ngroup = length(i),
                ncores = 1))
        
        sim <- do.call(cbind, z$count)
        SingleCellExperiment(
            assays = list(counts = sim), 
            colData = colData(x))    
    }
    
}