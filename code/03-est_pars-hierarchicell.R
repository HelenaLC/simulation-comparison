suppressPackageStartupMessages({
    library(hierarchicell)
    library(SingleCellExperiment)
})

fun <- function(x) {
    y <- counts(x)
    if (!is.matrix(y))
        y <- as.matrix(y)
    if (is.null(x$batch)) {
        # split cells into random batches
        batch_ids <- sample(2, ncol(x), TRUE)
        n_batches <- 0
    } else {
        batch_ids <- x$batch
        n_batches <- length(unique(batch_ids))
    }
    df <- data.frame(seq(ncol(x)), batch_ids, t(y))
    z <- filter_counts(df, gene_thresh = 0, cell_thresh = 0)
    p <- compute_data_summaries(expr = z, type = "Raw")
    # single group 2 cell is required
    # for simulation to pass successfully
    list(
        data_summaries = p,
        n_genes = nrow(x),
        n_cases = 1,
        cells_per_case = 1,
        n_controls = length(unique(batch_ids)),
        cells_per_control = tabulate(batch_ids),
        ncells_variation_type = "Fixed",
        n_batches = n_batches,
        batch_ids = batch_ids)
}
