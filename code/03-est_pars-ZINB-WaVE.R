suppressPackageStartupMessages({
    library(BiocParallel)
    library(SingleCellExperiment)
    library(zinbwave)
})

fun <- function(x) {
    cd <- data.frame(colData(x))
    i <- c("cluster", "batch")
    i <- intersect(i, names(cd))
    
    y <- if (length(i) == 0) {
        zinbFit(x, 
            verbose = FALSE,
            BPPARAM = SerialParam())
    } else {
        zinbFit(x, 
            model.matrix(~cd[[i]]),
            verbose = FALSE,
            BPPARAM = SerialParam())
    }
    x <- list(obj = y, cd = colData(x))
}
