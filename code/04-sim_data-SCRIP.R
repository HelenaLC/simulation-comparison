suppressPackageStartupMessages({
    library(checkmate)
    library(SCRIP)
    library(Seurat)
    library(SingleCellExperiment)
})

fun <- function(x) {
    if (x$t == "foo") {
        y <- do.call(SCRIPsimu, x$p)
        metadata(y) <- list()
        rowData(y) <- colData(y) <- NULL
        assays(y) <- assays(y)["counts"]
    } else {
        # code bug requires 'CTlist' 
        # to be passed via environment
        env <- parent.frame()
        env$CTlist <- x$p$CTlist
        x$p$CTlist <- NULL
        sink(tempfile())
        y <- do.call(simu_cluster, x$p, envir = env)
        sink()
        cd <- DataFrame(y$CT.infor)
        names(cd) <- x$t
        y <- SingleCellExperiment(
            list(counts = y$final), 
            colData = cd)
        # make cell names unique across clusters
        colnames(y) <- paste0("cell", seq(ncol(y)))
    }
    return(y)
}