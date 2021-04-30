suppressPackageStartupMessages({
    library(SingleCellExperiment)
})

x <- readRDS(args$est)
if (is.null(x))
    x <- readRDS(args$sub)

source(args$fun)
t <- system.time(y <- fun(x))[[3]]

t <- data.frame(wcs,
    n_genes = nrow(y),
    n_cells = ncol(y),
    runtime = t)

saveRDS(t, args$rt)
saveRDS(y, args$sim)