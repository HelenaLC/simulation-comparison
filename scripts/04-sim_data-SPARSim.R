suppressPackageStartupMessages({
    library(SPARSim)
    library(SingleCellExperiment)
})

fun <- function(x) {
    
    sink(tempfile())
    y <- SPARSim_simulation(x$estimate, output_batch_matrix = TRUE)
    sink()
    
    y <- y$count_matrix  
    
    if(is.null(x$batch)){
        SingleCellExperiment(
            assays = list(counts = y))
    }else{
        SingleCellExperiment(
            assays = list(counts = y),
            colData=data.frame(batch=x$batch))
    }
    
}