suppressPackageStartupMessages({
  library(scater)
  library(SPARSim)
  library(SingleCellExperiment)
})

fun <- function(x)
{
    y <- counts(x)
    if (!is.matrix(y))
        y <- as.matrix(y)
    
    SPARSim_estimate_parameter_from_data(
        raw_data = y,
        norm_data = normalizeCounts(y),
        conditions = list(seq_len(ncol(x))))
}
