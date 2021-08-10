source(args$fun)
sce <- readRDS(args$sce)
res <- fun(sce)

res <- data.frame(wcs, 
    row.names = NULL,
    pred = as.integer(res),
    true = as.integer(droplevels(factor(sce$cluster))))

saveRDS(res, args$res)
