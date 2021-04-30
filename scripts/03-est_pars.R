suppressPackageStartupMessages({
    library(SingleCellExperiment)
})

source(args$fun)
x <- readRDS(args$sub)

t <- system.time(y <- fun(x))[[3]]
if (is.null(y)) t <- NA

t <- data.frame(wcs,
    n_genes = nrow(x),
    n_cells = ncol(x),
    runtime = t)

saveRDS(t, args$rt)
saveRDS(y, args$est)