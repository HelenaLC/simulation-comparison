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
    
    if(!is.null(x$batch)){
      conditions <- list()
      for (batch_name in unique(x$batch)) {
        conditions[[batch_name]] <- which(x$batch %in% batch_name)
      }
    }else{
      conditions <- list(seq_len(ncol(x)))
    }
    
    estimate <- SPARSim_estimate_parameter_from_data(
        raw_data = y,
        norm_data = normalizeCounts(y),
        conditions = conditions)
    
    if(!is.null(x$batch)){
      list(estimate = estimate, batch=x$batch)
    }else{
      list(estimate=estimate)
    }
}
