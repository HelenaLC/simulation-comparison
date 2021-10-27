x <- readRDS(args$est)


y <- if (!isTRUE(is.na(x))) { # skip simulation if estimation failed
    if (is.null(x))   # use dataset if there's no separate estimation step
        x <- readRDS(args$sub)
    
    source(args$fun)
    tryCatch(fun(x), 
        error = function(e) NULL)
}

if (!is.null(y)) {
    z <- assay(y)
    y <- y[
        rowSums(z) > 0,
        colSums(z) > 0]
    dimnames(y) <- list(
        paste0("gene", seq(nrow(y))),
        paste0("cell", seq(ncol(y))))
}

saveRDS(y, args$sim)