source(args$fun)
sce <- readRDS(args$sce)

# skip if simulation failed (return NULL)
res <- if (!is.null(sce)) fun(sce)

saveRDS(res, args$res)
