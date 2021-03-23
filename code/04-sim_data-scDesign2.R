suppressPackageStartupMessages({
    library(scDesign2)
    library(SingleCellExperiment)
})

fun <- function(x)
{
    # get number of cells per cluster
    n <- vapply(x, function(.) .$n_cell, numeric(1))
    # simulate data with equal number 
    # & proportion of cells per cluster
    y <- simulate_count_scDesign2(
        model_params = x, 
        n_cell_new = sum(n), 
        cell_type_prop = prop.table(n))
    # construct SCE
    cd <- if (length(x) > 1) 
        data.frame(cluster = colnames(y))
    SingleCellExperiment(
        assay = list(counts = unname(y)),
        colData = cd)
}
