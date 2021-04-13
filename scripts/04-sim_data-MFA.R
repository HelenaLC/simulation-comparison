suppressPackageStartupMessages({
    library(mfa)
    library(SingleCellExperiment)
})

fun <- function(x) {
    y <- do.call(create_synthetic, x)
    SingleCellExperiment(list(counts = y$X))
}
