suppressPackageStartupMessages({
    library(muscat)
    library(SingleCellExperiment)
})

fun <- function(x) {
    y <- simData(x, dd = FALSE)
    md <- metadata(y)

    if (!is.null(x$cluster_id)) {
        kids <- factor(y$cluster_id, labels = md$ref_kids)
        kids <- factor(kids, levels(x$cluster_id))
        y$cluster <- kids
        y$cluster_id <- NULL
    }
    if (!is.null(x$sample_id)) {
        bids <- factor(y$sample_id, labels = md$ref_sids)
        bids <- factor(bids, levels(x$sample_id))
        y$batch <- bids
        y$sample_id <- NULL
    }
    metadata(y) <- list()
    rowData(y) <- NULL
    return(y)
}
