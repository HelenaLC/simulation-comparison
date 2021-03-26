suppressPackageStartupMessages({
    library(splatter)
    library(SingleCellExperiment)
})

fun <- function(x) {
    nb <- getParam(x$params, "nBatches")
    nk <- getParam(x$params, "nGroups")
    method <- ifelse(nb > 1 || nk > 1, "groups", "single")
    y <- splatSimulate(x$params, method, verbose = FALSE)
    # keep variables of interest only
    nc <- getParam(x$params, "nCells")
    cd <- make_zero_col_DFrame(nc)
    if (nb > 1) cd$batch <- factor(y$Batch, labels = x$ids$batch)
    if (nk > 1) cd$cluster <- factor(y$Group, labels = x$ids$cluster)
    colData(y) <- cd
    # drop gene and global metadata
    rowData(y) <- NULL
    metadata(y) <- list()
    # keep counts only
    assays(y) <- assays(y)["counts"]
    return(y)
}