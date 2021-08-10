x <- readRDS(args$est)
if (is.null(x))
    x <- readRDS(args$sub)

source(args$fun)
y <- fun(x)
    
z <- assay(y)
y <- y[
    rowSums(z) > 0,
    colSums(z) > 0]

dimnames(y) <- list(
    paste0("gene", seq(nrow(y))),
    paste0("cell", seq(ncol(y))))

saveRDS(y, args$sim)