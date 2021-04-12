suppressPackageStartupMessages({
    library(scDesign2)
})

fun <- function(x) 
{
    if (is.null(x$cluster)) {
        x$id <- "foo" 
    } else {
        x$id <- x$cluster
    }
    colnames(x) <- x$id
    y <- fit_model_scDesign2(
        data_mat = counts(x),
        cell_type_sel = unique(x$id))
}