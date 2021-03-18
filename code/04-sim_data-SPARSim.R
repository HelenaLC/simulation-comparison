suppressPackageStartupMessages({
    library(SPARSim)
    library(SingleCellExperiment)
})

fun <- function(x) {
    
    sink(tempfile())
    y <- SPARSim_simulation(x)
    sink()
    
    SingleCellExperiment(
        assays = list(counts = y$count_matrix))
}