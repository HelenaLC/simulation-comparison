suppressPackageStartupMessages({
    library(splatter)
    library(SingleCellExperiment)
})

fun <- function(x) {
    y <- counts(x)
    if (!is.matrix(y))
        y <- as.matrix(y)
    
    cd <- data.frame(colData(x))
    i <- c("batch", "cluster")
    i <- intersect(i, names(cd))
    t <- ifelse(length(i) == 0, "foo", i)

    p <- if (t == "foo") {
        list(
            data = y,
            mode = "GP-trendedBCV",
            params = splatEstimate(y))
    } else {
        cd$cellType <- x[[i]]
        list(
            expre_data = y,
            mode = "GP-trendedBCV",
            pheno_data = cd,
            CTlist = unique(x[[i]]),
            nfeatures = nrow(x)) 
    }
    x <- list(p = p, t = t)
}
