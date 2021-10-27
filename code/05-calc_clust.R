source(args$fun)
sce <- readRDS(args$sce)

# skip if simulation failed (return NULL)
res <- if (!is.null(sce))
    data.frame(wcs, 
        row.names = NULL,
        pred = as.integer(as.integer(fun(sce))),
        true = as.integer(droplevels(factor(sce$cluster))))

saveRDS(res, args$res)
