suppressPackageStartupMessages({
    library(hierarchicell)
    library(SingleCellExperiment)
})

fun <- function(x) {
    args <- formals("simulate_hierarchicell")
    y <- do.call(
        simulate_hierarchicell, 
        x[names(x) %in% names(args)])
    # keep control cells only
    y <- y[y$Status == "Control", ] 
    y <- t(as.matrix(y[, grep("^Gene", names(y))]))
    cd <- if (x$n_batches != 0) {
        data.frame(batch = x$batch_ids)
    } else make_zero_col_DFrame(ncol(y))
    SingleCellExperiment(list(counts = y), colData = cd)
}