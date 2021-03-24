suppressPackageStartupMessages({
    library(SPARSim)
    library(SingleCellExperiment)
})

fun <- function(x) {
    
    sink(tempfile())
    y <- SPARSim_simulation(x)
    sink()
    
    y <- y$count_matrix
    SingleCellExperiment(
        assays = list(counts = y))
}