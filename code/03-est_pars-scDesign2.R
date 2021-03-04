suppressPackageStartupMessages({
    library(scDesign2)
})

fun <- function(x) 
{
    x <- readRDS("data/02-sub/Mereu20,CD4T.rds")
    x <- x[1:100, ]
    
    y <- counts(x)
    if (!is.matrix(y))
        y <- as.matrix(y)
    colnames(y) <- x$batch
    
    z <- fit_model_scDesign2(
        data_mat = y,
        cell_type_sel = x$batch)
}