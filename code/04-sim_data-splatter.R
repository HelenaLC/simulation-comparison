suppressPackageStartupMessages({
    library(splatter)
    library(SingleCellExperiment)
})

fun <- \(x) 
{
    f <- function(p) {
        y <- splatSimulate(p, verbose = FALSE)
        assays(y) <- assays(y)["counts"]
        rowData(y) <- colData(y) <- NULL
        metadata(y) <- list()
        return(y)
    }
    if (!is.null(x$type)) {
        y <- lapply(names(x$pars), 
            function(i) {
                y <- f(x$pars[[i]])
                y[[x$type]] <- i
                return(y)
            }
        )
        do.call(cbind, y)
    } else {
        f(x$pars)
    }
}